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
    public class CampaignCompletedConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<CampaignCompletedConsumer> _logger;

        public CampaignCompletedConsumer(HeartForCharityDbContext context, ILogger<CampaignCompletedConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(CampaignCompletedEvent evt)
        {
            _logger.LogInformation("Campaign {Id} completed: {Title}", evt.CampaignId, evt.CampaignTitle);

            var donorProfileIds = await _context.Donations
                .Where(d => d.CampaignId == evt.CampaignId
                         && d.Status == DonationStatus.Success
                         && d.UserProfileId != null)
                .Select(d => d.UserProfileId!.Value)
                .Distinct()
                .ToListAsync();

            if (donorProfileIds.Count == 0)
            {
                _logger.LogInformation("No donors to notify for campaign {Id}", evt.CampaignId);
                return;
            }

            var now = DateTime.UtcNow;
            foreach (var profileId in donorProfileIds)
            {
                _context.Notifications.Add(new Notification
                {
                    UserProfileId = profileId,
                    Title         = "Campaign Completed",
                    Message       = $"The campaign '{evt.CampaignTitle}' you supported has been successfully completed. Thank you!",
                    Type          = NotificationType.CampaignCompleted,
                    IsRead        = false,
                    SentDateTime  = now,
                    CreatedAt     = now
                });
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("{Count} notifications created for completed campaign {Id}",
                donorProfileIds.Count, evt.CampaignId);
        }
    }
}
