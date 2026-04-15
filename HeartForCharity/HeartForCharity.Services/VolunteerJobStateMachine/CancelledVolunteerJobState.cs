using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.VolunteerJobStateMachine
{
    public class CancelledVolunteerJobState : BaseVolunteerJobState
    {
        public CancelledVolunteerJobState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
