using EasyNetQ;
using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Messages;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;

namespace HeartForCharity.Services.VolunteerApplicationStateMachine
{
    public class PendingApplicationState : BaseApplicationState
    {
        private readonly IBus _bus;

        public PendingApplicationState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider,
            IBus bus)
            : base(context, currentUserService, serviceProvider)
        {
            _bus = bus;
        }

        public override async Task<VolunteerApplicationResponse> ApproveAsync(int id)
        {
            var application = await _context.VolunteerApplications
                .Include(a => a.VolunteerJob)
                .Include(a => a.UserProfile)
                .FirstOrDefaultAsync(a => a.VolunteerApplicationId == id);

            if (application == null)
                throw new UserException("Application not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || application.VolunteerJob.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only approve applications for your own volunteer jobs.");

            application.Status    = ApplicationStatus.Approved;
            application.UpdatedAt = DateTime.UtcNow;

            application.VolunteerJob.PositionsFilled++;
            application.VolunteerJob.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _bus.PubSub.PublishAsync(new ApplicationApprovedEvent
            {
                VolunteerApplicationId = application.VolunteerApplicationId,
                UserProfileId          = application.UserProfileId,
                JobTitle               = application.VolunteerJob.Title,
                ApplicantName          = application.UserProfile != null
                    ? $"{application.UserProfile.FirstName} {application.UserProfile.LastName}"
                    : string.Empty
            });

            return MapToResponse(application);
        }

        public override async Task<VolunteerApplicationResponse> RejectAsync(int id, ApplicationRejectRequest request)
        {
            var application = await _context.VolunteerApplications
                .Include(a => a.VolunteerJob)
                .Include(a => a.UserProfile)
                .FirstOrDefaultAsync(a => a.VolunteerApplicationId == id);

            if (application == null)
                throw new UserException("Application not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || application.VolunteerJob.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only reject applications for your own volunteer jobs.");

            application.Status          = ApplicationStatus.Rejected;
            application.RejectionReason = request.RejectionReason;
            application.UpdatedAt       = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _bus.PubSub.PublishAsync(new ApplicationRejectedEvent
            {
                VolunteerApplicationId = application.VolunteerApplicationId,
                UserProfileId          = application.UserProfileId,
                JobTitle               = application.VolunteerJob.Title,
                ApplicantName          = application.UserProfile != null
                    ? $"{application.UserProfile.FirstName} {application.UserProfile.LastName}"
                    : string.Empty,
                RejectionReason        = request.RejectionReason
            });

            return MapToResponse(application);
        }
    }
}
