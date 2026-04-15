using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.VolunteerApplicationStateMachine
{
    public class WithdrawnApplicationState : BaseApplicationState
    {
        public WithdrawnApplicationState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
