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
    public class CountryService : BaseCRUDService<CountryResponse, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        private readonly IMemoryCache _cache;

        public CountryService(HeartForCharityDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<CountryResponse>> GetAsync(CountrySearchObject search)
        {
            var cacheKey = $"countries:fts={search.FTS}:page={search.Page}:size={search.PageSize}";
            if (_cache.TryGetValue(cacheKey, out PagedResult<CountryResponse>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(cacheKey, result, System.TimeSpan.FromMinutes(10));
            return result;
        }

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            return query;
        }
    }
}
