using EasyNetQ;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using HeartForCharity.Subscriber.Consumers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = Host.CreateApplicationBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=210002;Trusted_Connection=True;TrustServerCertificate=True";

builder.Services.AddHeartForCharityDatabase(connectionString);
builder.Services.AddScoped<ApplicationApprovedConsumer>();
builder.Services.AddScoped<ApplicationRejectedConsumer>();

var host = builder.Build();

var bus = RabbitHutch.CreateBus("host=localhost;username=guest;password=guest");

await bus.PubSub.SubscribeAsync<ApplicationApprovedEvent>(
    "heartforcharity-approved",
    async msg =>
    {
        using var scope = host.Services.CreateScope();
        var consumer = scope.ServiceProvider.GetRequiredService<ApplicationApprovedConsumer>();
        await consumer.ConsumeAsync(msg);
    });

await bus.PubSub.SubscribeAsync<ApplicationRejectedEvent>(
    "heartforcharity-rejected",
    async msg =>
    {
        using var scope = host.Services.CreateScope();
        var consumer = scope.ServiceProvider.GetRequiredService<ApplicationRejectedConsumer>();
        await consumer.ConsumeAsync(msg);
    });

await host.RunAsync();

bus.Dispose();
