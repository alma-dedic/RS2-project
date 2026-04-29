using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using HeartForCharity.Services.VolunteerJobStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class VolunteerJobService : BaseCRUDService<VolunteerJobResponse, VolunteerJobSearchObject, VolunteerJob, VolunteerJobInsertRequest, VolunteerJobUpdateRequest>, IVolunteerJobService
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly BaseVolunteerJobState _baseState;

        public VolunteerJobService(
            HeartForCharityDbContext context,
            IMapper mapper,
            ICurrentUserService currentUserService,
            BaseVolunteerJobState baseState)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
            _baseState = baseState;
        }

        public async Task<VolunteerJobResponse> CompleteAsync(int id)
        {
            var job = await _context.VolunteerJobs.FindAsync(id);
            if (job == null)
                throw new UserException("Volunteer job not found.");

            var state = _baseState.GetState(job.Status);
            return await state.CompleteAsync(id);
        }

        public async Task<VolunteerJobResponse> CancelAsync(int id)
        {
            var job = await _context.VolunteerJobs.FindAsync(id);
            if (job == null)
                throw new UserException("Volunteer job not found.");

            var state = _baseState.GetState(job.Status);
            return await state.CancelAsync(id);
        }

        public async Task<PagedResult<VolunteerJobResponse>> GetMyAsync(VolunteerJobSearchObject search)
        {
            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null)
                throw new UserException("Organisation profile not found for current user.");

            search.OrganisationProfileId = orgProfile.OrganisationProfileId;
            return await GetAsync(search);
        }

        public override async Task<VolunteerJobResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.VolunteerJobs
                .Include(v => v.OrganisationProfile)
                .Include(v => v.Category)
                .Include(v => v.Address)
                    .ThenInclude(a => a!.City)
                .Include(v => v.VolunteerJobSkills)
                    .ThenInclude(vjs => vjs.Skill)
                .Where(v => v.DeletedAt == null)
                .FirstOrDefaultAsync(v => v.VolunteerJobId == id);

            if (entity == null) return null;
            return MapToResponse(entity);
        }

        protected override IQueryable<VolunteerJob> ApplyFilter(IQueryable<VolunteerJob> query, VolunteerJobSearchObject search)
        {
            query = query.Where(v => v.DeletedAt == null)
                         .Include(v => v.OrganisationProfile)
                         .Include(v => v.Category)
                         .Include(v => v.Address)
                         .ThenInclude(a => a!.City)
                         .Include(v => v.VolunteerJobSkills)
                         .ThenInclude(vjs => vjs.Skill);

            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(v => v.Title.Contains(search.FTS) || v.Description!.Contains(search.FTS));
            if (search.CategoryId.HasValue)
                query = query.Where(v => v.CategoryId == search.CategoryId);
            if (!string.IsNullOrWhiteSpace(search.Status) && Enum.TryParse<VolunteerJobStatus>(search.Status, out var status))
                query = query.Where(v => v.Status == status);
            if (search.OrganisationProfileId.HasValue)
                query = query.Where(v => v.OrganisationProfileId == search.OrganisationProfileId);
            if (search.IsRemote.HasValue)
                query = query.Where(v => v.IsRemote == search.IsRemote);
            if (search.CityId.HasValue)
                query = query.Where(v => v.Address != null && v.Address.CityId == search.CityId);
            if (search.StartDateFrom.HasValue)
                query = query.Where(v => v.StartDate >= search.StartDateFrom.Value);
            if (search.StartDateTo.HasValue)
                query = query.Where(v => v.StartDate <= search.StartDateTo.Value);

            query = query.OrderByDescending(v => v.CreatedAt);

            return query;
        }

        protected override VolunteerJobResponse MapToResponse(VolunteerJob entity)
        {
            return new VolunteerJobResponse
            {
                VolunteerJobId        = entity.VolunteerJobId,
                OrganisationProfileId = entity.OrganisationProfileId,
                OrganisationName      = entity.OrganisationProfile?.Name ?? string.Empty,
                CategoryId            = entity.CategoryId,
                CategoryName          = entity.Category?.Name,
                Title                 = entity.Title,
                Description           = entity.Description,
                RequiredSkills        = entity.VolunteerJobSkills
                                              .Select(vjs => new Model.Responses.SkillResponse
                                              {
                                                  SkillId     = vjs.SkillId,
                                                  Name        = vjs.Skill?.Name ?? string.Empty,
                                                  Description = vjs.Skill?.Description
                                              })
                                              .ToList(),
                StartDate             = entity.StartDate,
                EndDate               = entity.EndDate,
                IsRemote              = entity.IsRemote,
                PositionsAvailable    = entity.PositionsAvailable,
                PositionsFilled       = entity.PositionsFilled,
                Status                = entity.Status.ToString(),
                AddressId             = entity.AddressId,
                CityId                = entity.Address?.CityId,
                CountryId             = entity.Address?.City?.CountryId,
                CityName              = entity.Address?.City?.Name,
                CreatedAt             = entity.CreatedAt
            };
        }

        protected override async Task BeforeInsert(VolunteerJob entity, VolunteerJobInsertRequest request)
        {
            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null)
                throw new UserException("Organisation profile not found for current user.");

            entity.OrganisationProfileId = orgProfile.OrganisationProfileId;
            entity.Status                = VolunteerJobStatus.Active;
            entity.PositionsFilled       = 0;
            entity.CreatedAt             = DateTime.UtcNow;
            entity.UpdatedAt             = DateTime.UtcNow;

            foreach (var skillId in request.SkillIds.Distinct())
                entity.VolunteerJobSkills.Add(new VolunteerJobSkill { SkillId = skillId });
        }

        protected override async Task BeforeUpdate(VolunteerJob entity, VolunteerJobUpdateRequest request)
        {
            var orgProfile = await _context.OrganisationProfiles.FindAsync(entity.OrganisationProfileId);

            if (orgProfile == null || orgProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only edit your own volunteer jobs.");

            if (entity.Status != VolunteerJobStatus.Active)
                throw new UserException("You can only edit active volunteer jobs.");

            entity.UpdatedAt = DateTime.UtcNow;

            var existing = await _context.VolunteerJobSkills
                .Where(vjs => vjs.VolunteerJobId == entity.VolunteerJobId)
                .ToListAsync();
            _context.VolunteerJobSkills.RemoveRange(existing);

            foreach (var skillId in request.SkillIds.Distinct())
                _context.VolunteerJobSkills.Add(new VolunteerJobSkill { VolunteerJobId = entity.VolunteerJobId, SkillId = skillId });
        }

        protected override async Task BeforeDelete(VolunteerJob entity)
        {
            var orgProfile = await _context.OrganisationProfiles.FindAsync(entity.OrganisationProfileId);

            if (orgProfile == null || orgProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only delete your own volunteer jobs.");

            if (entity.Status != VolunteerJobStatus.Active)
                throw new UserException("You can only delete active volunteer jobs.");

            if (entity.PositionsFilled > 0)
                throw new UserException("Cannot delete a volunteer job that has approved volunteers.");
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<VolunteerJob>().FindAsync(id);
            if (entity == null) return false;

            await BeforeDelete(entity);

            entity.DeletedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
