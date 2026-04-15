using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.VolunteerApplicationStateMachine
{
    public class RejectedApplicationState : BaseApplicationState
    {
        public RejectedApplicationState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
