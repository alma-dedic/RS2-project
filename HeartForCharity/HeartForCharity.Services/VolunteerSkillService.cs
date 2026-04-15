using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class VolunteerSkillService : BaseCRUDService<VolunteerSkillResponse, VolunteerSkillSearchObject, VolunteerSkill, VolunteerSkillInsertRequest, VolunteerSkillInsertRequest>, IVolunteerSkillService
    {
        private readonly ICurrentUserService _currentUserService;

        public VolunteerSkillService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<VolunteerSkill> ApplyFilter(IQueryable<VolunteerSkill> query, VolunteerSkillSearchObject search)
        {
            query = query.Include(vs => vs.Skill);
            if (search.UserProfileId.HasValue)
                query = query.Where(vs => vs.UserProfileId == search.UserProfileId);
            if (search.SkillId.HasValue)
                query = query.Where(vs => vs.SkillId == search.SkillId);
            return query;
        }

        protected override VolunteerSkillResponse MapToResponse(VolunteerSkill entity)
        {
            return new VolunteerSkillResponse
            {
                VolunteerSkillId = entity.VolunteerSkillId,
                UserProfileId = entity.UserProfileId,
                SkillId = entity.SkillId,
                SkillName = entity.Skill?.Name ?? string.Empty,
                SkillDescription = entity.Skill?.Description,
                CreatedAt = entity.CreatedAt
            };
        }

        protected override async Task BeforeInsert(VolunteerSkill entity, VolunteerSkillInsertRequest request)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            var alreadyExists = await _context.VolunteerSkills
                .AnyAsync(vs => vs.UserProfileId == userProfile.UserProfileId
                             && vs.SkillId == entity.SkillId);

            if (alreadyExists)
                throw new UserException("This skill is already added to your profile.");

            entity.UserProfileId = userProfile.UserProfileId;
            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeDelete(VolunteerSkill entity)
        {
            var userProfile = await _context.UserProfiles.FindAsync(entity.UserProfileId);

            if (userProfile == null || userProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only remove your own skills.");
        }
    }
}
