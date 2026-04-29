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
    public class OrganisationTypeService : BaseCRUDService<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationType, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest>, IOrganisationTypeService
    {
        private readonly IMemoryCache _cache;
        private static CancellationTokenSource _cacheReset = new();

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
            _cache.Set(cacheKey, result, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
                ExpirationTokens = { new CancellationChangeToken(_cacheReset.Token) }
            });
            return result;
        }

        public override async Task<OrganisationTypeResponse> CreateAsync(OrganisationTypeUpsertRequest request)
        {
            var result = await base.CreateAsync(request);
            InvalidateCache();
            return result;
        }

        public override async Task<OrganisationTypeResponse?> UpdateAsync(int id, OrganisationTypeUpsertRequest request)
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

        protected override IQueryable<OrganisationType> ApplyFilter(IQueryable<OrganisationType> query, OrganisationTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(o => o.Name.Contains(search.FTS));
            return query.OrderByDescending(o => o.OrganisationTypeId);
        }

        protected override async Task BeforeDelete(OrganisationType entity)
        {
            var inUse = await _context.OrganisationProfiles.AnyAsync(o => o.OrganisationTypeId == entity.OrganisationTypeId);

            if (inUse)
                throw new UserException("Cannot delete this organisation type because it is in use.");
        }
    }
}
