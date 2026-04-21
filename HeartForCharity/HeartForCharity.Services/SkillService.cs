using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.Extensions.Caching.Memory;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class SkillService : BaseCRUDService<SkillResponse, SkillSearchObject, Skill, SkillUpsertRequest, SkillUpsertRequest>, ISkillService
    {
        private readonly IMemoryCache _cache;

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
            _cache.Set(cacheKey, result, System.TimeSpan.FromMinutes(10));
            return result;
        }

        protected override IQueryable<Skill> ApplyFilter(IQueryable<Skill> query, SkillSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(s => s.Name.Contains(search.FTS));
            return query;
        }
    }
}
