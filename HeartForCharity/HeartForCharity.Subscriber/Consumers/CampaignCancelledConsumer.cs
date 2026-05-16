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
    public class CampaignCancelledConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<CampaignCancelledConsumer> _logger;

        public CampaignCancelledConsumer(HeartForCharityDbContext context, ILogger<CampaignCancelledConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(CampaignCancelledEvent evt)
        {
            _logger.LogInformation("Campaign {Id} cancelled: {Title}", evt.CampaignId, evt.CampaignTitle);

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
                    Title         = "Campaign Cancelled",
                    Message       = $"The campaign '{evt.CampaignTitle}' you supported has been cancelled. Please contact the organisation for details.",
                    Type          = NotificationType.CampaignCancelled,
                    IsRead        = false,
                    SentDateTime  = now,
                    CreatedAt     = now
                });
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("{Count} notifications created for cancelled campaign {Id}",
                donorProfileIds.Count, evt.CampaignId);
        }
    }
}
