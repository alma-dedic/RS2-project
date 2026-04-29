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
    public class CountryService : BaseCRUDService<CountryResponse, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        private readonly IMemoryCache _cache;
        private static CancellationTokenSource _cacheReset = new();

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
            _cache.Set(cacheKey, result, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
                ExpirationTokens = { new CancellationChangeToken(_cacheReset.Token) }
            });
            return result;
        }

        public override async Task<CountryResponse> CreateAsync(CountryUpsertRequest request)
        {
            var result = await base.CreateAsync(request);
            InvalidateCache();
            return result;
        }

        public override async Task<CountryResponse?> UpdateAsync(int id, CountryUpsertRequest request)
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

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            return query.OrderByDescending(c => c.CountryId);
        }

        protected override async Task BeforeDelete(Country entity)
        {
            var inUse = await _context.Cities.AnyAsync(c => c.CountryId == entity.CountryId);

            if (inUse)
                throw new UserException("Cannot delete this country because it is in use.");
        }
    }
}
