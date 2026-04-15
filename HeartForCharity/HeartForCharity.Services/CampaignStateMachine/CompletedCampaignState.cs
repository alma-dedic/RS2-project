using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.CampaignStateMachine
{
    public class CompletedCampaignState : BaseCampaignState
    {
        public CompletedCampaignState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
