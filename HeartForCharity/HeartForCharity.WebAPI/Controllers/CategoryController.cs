using HeartForCharity.Model.Constants;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CategoryController : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
        public CategoryController(ICategoryService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CategoryResponse>> Get([FromQuery] CategorySearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<CategoryResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override async Task<CategoryResponse> Create([FromBody] CategoryUpsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override async Task<CategoryResponse?> Update(int id, [FromBody] CategoryUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
