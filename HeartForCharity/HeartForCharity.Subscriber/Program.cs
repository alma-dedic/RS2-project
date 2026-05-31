using EasyNetQ;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using HeartForCharity.Subscriber.Consumers;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var searchDir = AppContext.BaseDirectory;
while (searchDir != null)
{
    var candidate = Path.Combine(searchDir, "HeartForCharity.WebAPI", ".env");
    if (File.Exists(candidate))
    {
        DotNetEnv.Env.Load(candidate);
        break;
    }
    searchDir = Directory.GetParent(searchDir)?.FullName;
}

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

var rabbitConnection = builder.Configuration["RabbitMQ:Connection"]
    ?? throw new InvalidOperationException("'RabbitMQ:Connection' is not configured.");

builder.Services.AddHeartForCharityDatabase(connectionString);
builder.Services.AddScoped<ApplicationApprovedConsumer>();
builder.Services.AddScoped<ApplicationRejectedConsumer>();
builder.Services.AddScoped<DonationSuccessfulConsumer>();
builder.Services.AddScoped<CampaignCompletedConsumer>();
builder.Services.AddScoped<CampaignCancelledConsumer>();
builder.Services.AddScoped<VolunteerJobCompletedConsumer>();
builder.Services.AddScoped<VolunteerJobCancelledConsumer>();

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

await bus.PubSub.SubscribeAsync<DonationSuccessfulEvent>(
    "heartforcharity-donation-successful",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<DonationSuccessfulConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(DonationSuccessfulEvent), msg.DonationId);
    });

await bus.PubSub.SubscribeAsync<CampaignCompletedEvent>(
    "heartforcharity-campaign-completed",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<CampaignCompletedConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(CampaignCompletedEvent), msg.CampaignId);
    });

await bus.PubSub.SubscribeAsync<CampaignCancelledEvent>(
    "heartforcharity-campaign-cancelled",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<CampaignCancelledConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(CampaignCancelledEvent), msg.CampaignId);
    });

await bus.PubSub.SubscribeAsync<VolunteerJobCompletedEvent>(
    "heartforcharity-job-completed",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<VolunteerJobCompletedConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(VolunteerJobCompletedEvent), msg.VolunteerJobId);
    });

await bus.PubSub.SubscribeAsync<VolunteerJobCancelledEvent>(
    "heartforcharity-job-cancelled",
    async msg =>
    {
        await ExecuteWithRetryAsync(async () =>
        {
            using var scope = host.Services.CreateScope();
            var consumer = scope.ServiceProvider.GetRequiredService<VolunteerJobCancelledConsumer>();
            await consumer.ConsumeAsync(msg);
        }, logger, nameof(VolunteerJobCancelledEvent), msg.VolunteerJobId);
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
