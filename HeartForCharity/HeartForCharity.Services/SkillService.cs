using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Primitives;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class SkillService : BaseCRUDService<SkillResponse, SkillSearchObject, Skill, SkillUpsertRequest, SkillUpsertRequest>, ISkillService
    {
        private readonly IMemoryCache _cache;
        private static CancellationTokenSource _cacheReset = new();

        public SkillService(HeartForCharityDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<SkillResponse>> GetAsync(SkillSearchObject search)
        {
            var cacheKey = $"skills:fts={search.FTS}:page={search.Page}:size={search.PageSize}";
            if (_cache.TryGetValue(cacheKey, out PagedResult<SkillResponse>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(cacheKey, result, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
                ExpirationTokens = { new CancellationChangeToken(_cacheReset.Token) }
            });
            return result;
        }

        public override async Task<SkillResponse> CreateAsync(SkillUpsertRequest request)
        {
            var result = await base.CreateAsync(request);
            InvalidateCache();
            return result;
        }

        public override async Task<SkillResponse?> UpdateAsync(int id, SkillUpsertRequest request)
        {
            var result = await base.UpdateAsync(id, request);
            InvalidateCache();
            return result;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var deleted = await base.DeleteAsync(id);
            if (deleted) InvalidateCache();
            return deleted;
        }

        private static void InvalidateCache()
        {
            var oldSource = _cacheReset;
            _cacheReset = new CancellationTokenSource();
            oldSource.Cancel();
        }

        protected override IQueryable<Skill> ApplyFilter(IQueryable<Skill> query, SkillSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(s => s.Name.Contains(search.FTS));
            return query.OrderByDescending(s => s.SkillId);
        }

        protected override async Task BeforeDelete(Skill entity)
        {
            var inUse = await _context.VolunteerSkills.AnyAsync(vs => vs.SkillId == entity.SkillId)
                     || await _context.VolunteerJobSkills.AnyAsync(vjs => vjs.SkillId == entity.SkillId);

            if (inUse)
                throw new UserException("Cannot delete this skill because it is in use.");
        }
    }
}
