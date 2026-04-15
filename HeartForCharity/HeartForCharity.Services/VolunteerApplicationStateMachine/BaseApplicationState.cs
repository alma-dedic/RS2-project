using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading.Tasks;

namespace HeartForCharity.Services.VolunteerApplicationStateMachine
{
    public class BaseApplicationState
    {
        protected readonly HeartForCharityDbContext _context;
        protected readonly ICurrentUserService _currentUserService;
        protected readonly IServiceProvider _serviceProvider;

        public BaseApplicationState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
        {
            _context = context;
            _currentUserService = currentUserService;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<VolunteerApplicationResponse> ApproveAsync(int id)
            => throw new UserException("Action not allowed in current application status.");

        public virtual Task<VolunteerApplicationResponse> RejectAsync(int id, ApplicationRejectRequest request)
            => throw new UserException("Action not allowed in current application status.");

        public BaseApplicationState GetState(ApplicationStatus status) => status switch
        {
            ApplicationStatus.Pending   => _serviceProvider.GetRequiredService<PendingApplicationState>(),
            ApplicationStatus.Approved  => _serviceProvider.GetRequiredService<ApprovedApplicationState>(),
            ApplicationStatus.Rejected  => _serviceProvider.GetRequiredService<RejectedApplicationState>(),
            ApplicationStatus.Withdrawn => _serviceProvider.GetRequiredService<WithdrawnApplicationState>(),
            _ => throw new UserException($"Unknown application status: {status}")
        };

        protected static VolunteerApplicationResponse MapToResponse(VolunteerApplication entity) => new()
        {
            VolunteerApplicationId = entity.VolunteerApplicationId,
            VolunteerJobId         = entity.VolunteerJobId,
            JobTitle               = entity.VolunteerJob?.Title ?? string.Empty,
            UserProfileId          = entity.UserProfileId,
            ApplicantName          = entity.UserProfile != null
                                        ? $"{entity.UserProfile.FirstName} {entity.UserProfile.LastName}"
                                        : string.Empty,
            CoverLetter            = entity.CoverLetter,
            ResumeUrl              = entity.ResumeUrl,
            Status                 = entity.Status.ToString(),
            RejectionReason        = entity.RejectionReason,
            IsCompleted            = entity.IsCompleted,
            AppliedAt              = entity.AppliedAt,
            UpdatedAt              = entity.UpdatedAt
        };
    }
}
