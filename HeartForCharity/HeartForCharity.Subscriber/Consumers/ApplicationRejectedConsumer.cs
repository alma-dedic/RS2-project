using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace HeartForCharity.Subscriber.Consumers
{
    public class ApplicationRejectedConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<ApplicationRejectedConsumer> _logger;

        public ApplicationRejectedConsumer(HeartForCharityDbContext context, ILogger<ApplicationRejectedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(ApplicationRejectedEvent evt)
        {
            _logger.LogInformation("Application {Id} rejected for {Name} - Job: {Job}",
                evt.VolunteerApplicationId, evt.ApplicantName, evt.JobTitle);

            var message = string.IsNullOrWhiteSpace(evt.RejectionReason)
                ? $"Unfortunately, your application for '{evt.JobTitle}' was not successful."
                : $"Unfortunately, your application for '{evt.JobTitle}' was not successful. Reason: {evt.RejectionReason}";

            var notification = new Notification
            {
                UserProfileId          = evt.UserProfileId,
                VolunteerApplicationId = evt.VolunteerApplicationId,
                Title                  = "Application Rejected",
                Message                = message,
                Type                   = NotificationType.ApplicationRejected,
                IsRead                 = false,
                SentDateTime           = DateTime.UtcNow,
                CreatedAt              = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Notification created for UserProfile {Id}", evt.UserProfileId);
        }
    }
}
