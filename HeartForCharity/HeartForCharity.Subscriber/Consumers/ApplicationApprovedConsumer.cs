using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace HeartForCharity.Subscriber.Consumers
{
    public class ApplicationApprovedConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<ApplicationApprovedConsumer> _logger;

        public ApplicationApprovedConsumer(HeartForCharityDbContext context, ILogger<ApplicationApprovedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(ApplicationApprovedEvent evt)
        {
            _logger.LogInformation("Application {Id} approved for {Name} - Job: {Job}",
                evt.VolunteerApplicationId, evt.ApplicantName, evt.JobTitle);

            var notification = new Notification
            {
                UserProfileId          = evt.UserProfileId,
                VolunteerApplicationId = evt.VolunteerApplicationId,
                Title                  = "Application Approved",
                Message                = $"Congratulations! Your application for '{evt.JobTitle}' has been approved.",
                Type                   = NotificationType.ApplicationApproved,
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
