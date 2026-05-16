using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Subscriber.Consumers
{
    public class VolunteerJobCompletedConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<VolunteerJobCompletedConsumer> _logger;

        public VolunteerJobCompletedConsumer(HeartForCharityDbContext context, ILogger<VolunteerJobCompletedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(VolunteerJobCompletedEvent evt)
        {
            _logger.LogInformation("Volunteer job {Id} completed: {Title}", evt.VolunteerJobId, evt.JobTitle);

            var applications = await _context.VolunteerApplications
                .Where(a => a.VolunteerJobId == evt.VolunteerJobId
                         && a.Status == ApplicationStatus.Approved)
                .ToListAsync();

            if (applications.Count == 0)
            {
                _logger.LogInformation("No approved volunteers to notify for job {Id}", evt.VolunteerJobId);
                return;
            }

            var now = DateTime.UtcNow;
            foreach (var app in applications)
            {
                _context.Notifications.Add(new Notification
                {
                    UserProfileId          = app.UserProfileId,
                    VolunteerApplicationId = app.VolunteerApplicationId,
                    Title                  = "Volunteer Job Completed",
                    Message                = $"The volunteer job '{evt.JobTitle}' is now completed. You can now leave a review!",
                    Type                   = NotificationType.VolunteerJobCompleted,
                    IsRead                 = false,
                    SentDateTime           = now,
                    CreatedAt              = now
                });
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("{Count} notifications created for completed volunteer job {Id}",
                applications.Count, evt.VolunteerJobId);
        }
    }
}
