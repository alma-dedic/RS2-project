using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.CampaignStateMachine
{
    public class CancelledCampaignState : BaseCampaignState
    {
        public CancelledCampaignState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
