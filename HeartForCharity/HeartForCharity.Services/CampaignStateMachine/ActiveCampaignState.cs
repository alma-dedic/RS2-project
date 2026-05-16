using EasyNetQ;
using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Messages;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services.CampaignStateMachine
{
    public class ActiveCampaignState : BaseCampaignState
    {
        private readonly IBus _bus;

        public ActiveCampaignState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider,
            IBus bus)
            : base(context, currentUserService, serviceProvider)
        {
            _bus = bus;
        }

        public override async Task<CampaignResponse> CompleteAsync(int id)
        {
            var campaign = await _context.Campaigns
                .Include(c => c.OrganisationProfile)
                .Include(c => c.Category)
                .Include(c => c.CampaignMedias)
                .Include(c => c.Donations)
                .FirstOrDefaultAsync(c => c.CampaignId == id);

            if (campaign == null)
                throw new UserException("Campaign not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || campaign.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only complete your own campaigns.");

            campaign.Status    = CampaignStatus.Completed;
            campaign.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _bus.PubSub.PublishAsync(new CampaignCompletedEvent
            {
                CampaignId    = campaign.CampaignId,
                CampaignTitle = campaign.Title
            });

            return MapToResponse(campaign);
        }

        public override async Task<CampaignResponse> CancelAsync(int id)
        {
            var campaign = await _context.Campaigns
                .Include(c => c.OrganisationProfile)
                .Include(c => c.Category)
                .Include(c => c.CampaignMedias)
                .Include(c => c.Donations)
                .FirstOrDefaultAsync(c => c.CampaignId == id);

            if (campaign == null)
                throw new UserException("Campaign not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || campaign.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only cancel your own campaigns.");

            campaign.Status    = CampaignStatus.Cancelled;
            campaign.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _bus.PubSub.PublishAsync(new CampaignCancelledEvent
            {
                CampaignId    = campaign.CampaignId,
                CampaignTitle = campaign.Title
            });

            return MapToResponse(campaign);
        }
    }
}
