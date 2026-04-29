using HeartForCharity.Model.Enums;
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
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        private readonly IMemoryCache _cache;
        private static CancellationTokenSource _cacheReset = new();

        public CategoryService(HeartForCharityDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<CategoryResponse>> GetAsync(CategorySearchObject search)
        {
            var cacheKey = $"categories:fts={search.FTS}:appliesTo={search.AppliesTo}:page={search.Page}:size={search.PageSize}";
            if (_cache.TryGetValue(cacheKey, out PagedResult<CategoryResponse>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(cacheKey, result, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
                ExpirationTokens = { new CancellationChangeToken(_cacheReset.Token) }
            });
            return result;
        }

        public override async Task<CategoryResponse> CreateAsync(CategoryUpsertRequest request)
        {
            var result = await base.CreateAsync(request);
            InvalidateCache();
            return result;
        }

        public override async Task<CategoryResponse?> UpdateAsync(int id, CategoryUpsertRequest request)
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

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            if (!string.IsNullOrWhiteSpace(search.AppliesTo) && System.Enum.TryParse<CategoryAppliesTo>(search.AppliesTo, out var appliesTo))
                query = query.Where(c => c.AppliesTo == appliesTo || c.AppliesTo == CategoryAppliesTo.Both);
            return query.OrderByDescending(c => c.CategoryId);
        }

        protected override async Task BeforeDelete(Category entity)
        {
            var inUse = await _context.Campaigns.AnyAsync(c => c.CategoryId == entity.CategoryId)
                     || await _context.VolunteerJobs.AnyAsync(j => j.CategoryId == entity.CategoryId);

            if (inUse)
                throw new UserException("Cannot delete this category because it is in use.");
        }
    }
}
