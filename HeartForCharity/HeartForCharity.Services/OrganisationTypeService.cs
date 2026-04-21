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
    public class OrganisationTypeService : BaseCRUDService<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationType, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest>, IOrganisationTypeService
    {
        private readonly IMemoryCache _cache;

        public OrganisationTypeService(HeartForCharityDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<OrganisationTypeResponse>> GetAsync(OrganisationTypeSearchObject search)
        {
            var cacheKey = $"org-types:fts={search.FTS}:page={search.Page}:size={search.PageSize}";
            if (_cache.TryGetValue(cacheKey, out PagedResult<OrganisationTypeResponse>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(cacheKey, result, System.TimeSpan.FromMinutes(10));
            return result;
        }

        protected override IQueryable<OrganisationType> ApplyFilter(IQueryable<OrganisationType> query, OrganisationTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(o => o.Name.Contains(search.FTS));
            return query;
        }
    }
}
