using HeartForCharity.Services.Database;
using System;

namespace HeartForCharity.Services.VolunteerJobStateMachine
{
    public class CompletedVolunteerJobState : BaseVolunteerJobState
    {
        public CompletedVolunteerJobState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }
    }
}
