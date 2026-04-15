using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;

namespace HeartForCharity.Services.VolunteerJobStateMachine
{
    public class ActiveVolunteerJobState : BaseVolunteerJobState
    {
        public ActiveVolunteerJobState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
            : base(context, currentUserService, serviceProvider) { }

        public override async Task<VolunteerJobResponse> CompleteAsync(int id)
        {
            var job = await _context.VolunteerJobs
                .Include(v => v.OrganisationProfile)
                .Include(v => v.Category)
                .Include(v => v.Address).ThenInclude(a => a!.City)
                .FirstOrDefaultAsync(v => v.VolunteerJobId == id);

            if (job == null)
                throw new UserException("Volunteer job not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || job.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only complete your own volunteer jobs.");

            job.Status    = VolunteerJobStatus.Completed;
            job.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return MapToResponse(job);
        }

        public override async Task<VolunteerJobResponse> CancelAsync(int id)
        {
            var job = await _context.VolunteerJobs
                .Include(v => v.OrganisationProfile)
                .Include(v => v.Category)
                .Include(v => v.Address).ThenInclude(a => a!.City)
                .FirstOrDefaultAsync(v => v.VolunteerJobId == id);

            if (job == null)
                throw new UserException("Volunteer job not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null || job.OrganisationProfileId != orgProfile.OrganisationProfileId)
                throw new ForbiddenException("You can only cancel your own volunteer jobs.");

            job.Status    = VolunteerJobStatus.Cancelled;
            job.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return MapToResponse(job);
        }
    }
}
