using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.VolunteerApplicationStateMachine
{
    public class ApprovedApplicationState : BaseApplicationState
    {
        public ApprovedApplicationState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
