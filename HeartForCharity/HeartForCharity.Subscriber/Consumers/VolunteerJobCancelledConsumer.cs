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
    public class VolunteerJobCancelledConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<VolunteerJobCancelledConsumer> _logger;

        public VolunteerJobCancelledConsumer(HeartForCharityDbContext context, ILogger<VolunteerJobCancelledConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(VolunteerJobCancelledEvent evt)
        {
            _logger.LogInformation("Volunteer job {Id} cancelled: {Title}", evt.VolunteerJobId, evt.JobTitle);

            var applications = await _context.VolunteerApplications
                .Where(a => a.VolunteerJobId == evt.VolunteerJobId
                         && (a.Status == ApplicationStatus.Pending || a.Status == ApplicationStatus.Approved))
                .ToListAsync();

            if (applications.Count == 0)
            {
                _logger.LogInformation("No active applicants to notify for cancelled job {Id}", evt.VolunteerJobId);
                return;
            }

            var now = DateTime.UtcNow;
            foreach (var app in applications)
            {
                _context.Notifications.Add(new Notification
                {
                    UserProfileId          = app.UserProfileId,
                    VolunteerApplicationId = app.VolunteerApplicationId,
                    Title                  = "Volunteer Job Cancelled",
                    Message                = $"The volunteer job '{evt.JobTitle}' you applied for has been cancelled by the organisation.",
                    Type                   = NotificationType.VolunteerJobCancelled,
                    IsRead                 = false,
                    SentDateTime           = now,
                    CreatedAt              = now
                });
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("{Count} notifications created for cancelled volunteer job {Id}",
                applications.Count, evt.VolunteerJobId);
        }
    }
}
