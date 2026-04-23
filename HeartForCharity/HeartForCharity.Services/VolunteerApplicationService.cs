using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using HeartForCharity.Services.VolunteerApplicationStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class VolunteerApplicationService : BaseCRUDService<VolunteerApplicationResponse, VolunteerApplicationSearchObject, VolunteerApplication, VolunteerApplicationInsertRequest, VolunteerApplicationInsertRequest>, IVolunteerApplicationService
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly BaseApplicationState _baseState;

        public VolunteerApplicationService(
            HeartForCharityDbContext context,
            IMapper mapper,
            ICurrentUserService currentUserService,
            BaseApplicationState baseState)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
            _baseState = baseState;
        }

        public async Task<VolunteerApplicationResponse> ApproveAsync(int id)
        {
            var application = await _context.VolunteerApplications.FindAsync(id);
            if (application == null)
                throw new UserException("Application not found.");

            var state = _baseState.GetState(application.Status);
            return await state.ApproveAsync(id);
        }

        public async Task<VolunteerApplicationResponse> RejectAsync(int id, ApplicationRejectRequest request)
        {
            var application = await _context.VolunteerApplications.FindAsync(id);
            if (application == null)
                throw new UserException("Application not found.");

            var state = _baseState.GetState(application.Status);
            return await state.RejectAsync(id, request);
        }

        protected override IQueryable<VolunteerApplication> ApplyFilter(IQueryable<VolunteerApplication> query, VolunteerApplicationSearchObject search)
        {
            query = query.Include(va => va.VolunteerJob)
                         .Include(va => va.UserProfile)
                             .ThenInclude(up => up!.User)
                         .Include(va => va.UserProfile)
                             .ThenInclude(up => up!.Address)
                                 .ThenInclude(a => a!.City)
                         .Include(va => va.ReviewedByUser)
                             .ThenInclude(u => u!.OrganisationProfile)
                         .Include(va => va.Review);

            if (search.VolunteerJobId.HasValue)
                query = query.Where(va => va.VolunteerJobId == search.VolunteerJobId);
            if (search.UserProfileId.HasValue)
                query = query.Where(va => va.UserProfileId == search.UserProfileId);
            if (!string.IsNullOrWhiteSpace(search.Status) && Enum.TryParse<ApplicationStatus>(search.Status, out var status))
                query = query.Where(va => va.Status == status);
            if (search.IsCompleted.HasValue)
                query = query.Where(va => va.IsCompleted == search.IsCompleted);
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(va => va.UserProfile != null &&
                    (va.UserProfile.FirstName.Contains(search.FTS) || va.UserProfile.LastName.Contains(search.FTS)));

            return query;
        }

        protected override VolunteerApplicationResponse MapToResponse(VolunteerApplication entity)
        {
            return new VolunteerApplicationResponse
            {
                VolunteerApplicationId = entity.VolunteerApplicationId,
                VolunteerJobId         = entity.VolunteerJobId,
                JobTitle               = entity.VolunteerJob?.Title ?? string.Empty,
                UserProfileId          = entity.UserProfileId,
                ApplicantName   = entity.UserProfile != null
                    ? $"{entity.UserProfile.FirstName} {entity.UserProfile.LastName}"
                    : string.Empty,
                Email           = entity.UserProfile?.User?.Email,
                PhoneNumber     = entity.UserProfile?.PhoneNumber,
                DateOfBirth     = entity.UserProfile?.DateOfBirth,
                Address         = entity.UserProfile?.Address != null
                    ? string.Join(", ", new[]
                      {
                          entity.UserProfile.Address.StreetName,
                          entity.UserProfile.Address.Number,
                          entity.UserProfile.Address.PostalCode,
                          entity.UserProfile.Address.City?.Name
                      }.Where(s => !string.IsNullOrWhiteSpace(s)))
                    : null,
                CoverLetter     = entity.CoverLetter,
                ResumeUrl       = entity.ResumeUrl,
                Status          = entity.Status.ToString(),
                RejectionReason = entity.RejectionReason,
                IsCompleted      = entity.IsCompleted,
                HasReview        = entity.Review != null,
                ReviewedByName   = entity.ReviewedByUser?.OrganisationProfile?.Name
                                ?? entity.ReviewedByUser?.Username,
                ReviewedAt       = entity.ReviewedAt,
                AppliedAt        = entity.AppliedAt,
                UpdatedAt        = entity.UpdatedAt
            };
        }

        protected override async Task BeforeInsert(VolunteerApplication entity, VolunteerApplicationInsertRequest request)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            var job = await _context.VolunteerJobs.FindAsync(entity.VolunteerJobId);

            if (job == null)
                throw new UserException("Volunteer job not found.");

            if (job.Status != VolunteerJobStatus.Active)
                throw new UserException("You can only apply for active volunteer jobs.");

            if (job.PositionsFilled >= job.PositionsAvailable)
                throw new UserException("There are no available positions for this volunteer job.");

            var alreadyApplied = await _context.VolunteerApplications
                .AnyAsync(va => va.UserProfileId == userProfile.UserProfileId
                             && va.VolunteerJobId == entity.VolunteerJobId
                             && va.Status != ApplicationStatus.Withdrawn);

            if (alreadyApplied)
                throw new UserException("You have already applied for this volunteer job.");

            entity.UserProfileId = userProfile.UserProfileId;
            entity.Status        = ApplicationStatus.Pending;
            entity.IsCompleted   = false;
            entity.AppliedAt     = DateTime.UtcNow;
            entity.UpdatedAt     = DateTime.UtcNow;
        }

        public async Task<PagedResult<VolunteerApplicationResponse>> GetMyAsync(VolunteerApplicationSearchObject search)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            search.UserProfileId = userProfile.UserProfileId;
            return await GetAsync(search);
        }

        public async Task<bool> WithdrawAsync(int id)
        {
            var entity = await _context.VolunteerApplications.FindAsync(id);
            if (entity == null)
                return false;

            var userProfile = await _context.UserProfiles.FindAsync(entity.UserProfileId);
            if (userProfile == null || userProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only withdraw your own applications.");

            if (entity.Status != ApplicationStatus.Pending)
                throw new UserException("You can only withdraw pending applications.");

            entity.Status = ApplicationStatus.Withdrawn;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
