using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Messages;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.Logging;
using System;
using System.Globalization;
using System.Threading.Tasks;

namespace HeartForCharity.Subscriber.Consumers
{
    public class DonationSuccessfulConsumer
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ILogger<DonationSuccessfulConsumer> _logger;

        public DonationSuccessfulConsumer(HeartForCharityDbContext context, ILogger<DonationSuccessfulConsumer> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task ConsumeAsync(DonationSuccessfulEvent evt)
        {
            _logger.LogInformation("Donation {Id} successful for UserProfile {UserId} - Amount: {Amount} {Campaign}",
                evt.DonationId, evt.UserProfileId, evt.Amount, evt.CampaignTitle);

            if (evt.UserProfileId == 0)
            {
                _logger.LogWarning("DonationSuccessfulEvent has no UserProfileId; skipping notification.");
                return;
            }

            var notification = new Notification
            {
                UserProfileId = evt.UserProfileId,
                Title         = "Donation Successful",
                Message       = $"Thank you for your ${evt.Amount.ToString("F2", CultureInfo.InvariantCulture)} donation to '{evt.CampaignTitle}'.",
                Type          = NotificationType.DonationSuccessful,
                IsRead        = false,
                SentDateTime  = DateTime.UtcNow,
                CreatedAt     = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Notification created for UserProfile {Id}", evt.UserProfileId);
        }
    }
}
