using HeartForCharity.Model.Enums;
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
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        private readonly IMemoryCache _cache;

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
            _cache.Set(cacheKey, result, System.TimeSpan.FromMinutes(10));
            return result;
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            if (!string.IsNullOrWhiteSpace(search.AppliesTo) && System.Enum.TryParse<CategoryAppliesTo>(search.AppliesTo, out var appliesTo))
                query = query.Where(c => c.AppliesTo == appliesTo || c.AppliesTo == CategoryAppliesTo.Both);
            return query;
        }
    }
}
