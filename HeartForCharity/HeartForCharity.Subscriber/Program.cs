using EasyNetQ;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using HeartForCharity.Subscriber.Consumers;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

DotNetEnv.Env.TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

var rabbitConnection = builder.Configuration["RabbitMQ:Connection"]
    ?? throw new InvalidOperationException("'RabbitMQ:Connection' is not configured.");

builder.Services.AddHeartForCharityDatabase(connectionString);
builder.Services.AddScoped<ApplicationApprovedConsumer>();
builder.Services.AddScoped<ApplicationRejectedConsumer>();

var host = builder.Build();
var logger = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("HeartForCharity.Subscriber");

using var bus = RabbitHutch.CreateBus(rabbitConnection);

logger.LogInformation("Subscriber started. Listening for messages...");

await bus.PubSub.SubscribeAsync<ApplicationApprovedEvent>(
    "heartforcharity-approved",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<ApplicationApprovedConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(ApplicationApprovedEvent), msg.VolunteerApplicationId);
    });

await bus.PubSub.SubscribeAsync<ApplicationRejectedEvent>(
    "heartforcharity-rejected",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<ApplicationRejectedConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(ApplicationRejectedEvent), msg.VolunteerApplicationId);
    });

await host.RunAsync();


static async Task ExecuteWithRetryAsync(Func<Task> action, ILogger logger, string eventName, int messageId)
{
    int[] delays = [1000, 2000, 4000, 8000];

    for (int attempt = 0; attempt <= delays.Length; attempt++)
    {
        try
        {
            await action();
            return;
        }
        catch (Exception ex)
        {
            bool hasMoreRetries = attempt < delays.Length;
            if (hasMoreRetries)
            {
                logger.LogWarning(ex,
                    "Failed to process {EventName} (id={MessageId}) on attempt {Attempt}/{MaxAttempts}. Retrying in {Delay}ms.",
                    eventName, messageId, attempt + 1, delays.Length + 1, delays[attempt]);

                await Task.Delay(delays[attempt]);
            }
            else
            {
                logger.LogError(ex,
                    "Failed to process {EventName} (id={MessageId}) after {TotalAttempts} attempts. Message dropped.",
                    eventName, messageId, delays.Length + 1);
            }
        }
    }
}
