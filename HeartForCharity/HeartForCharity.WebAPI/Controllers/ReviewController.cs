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
    public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewInsertRequest>
    {
        public ReviewController(IReviewService service) : base(service) { }

        [Authorize]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<ReviewResponse>> Get([FromQuery] ReviewSearchObject? search = null)
            => await base.Get(search);

        [Authorize]
        [HttpGet("{id}")]
        public override async Task<ReviewResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.User)]
        [HttpPost]
        public override async Task<ReviewResponse> Create([FromBody] ReviewInsertRequest request)
            => await base.Create(request);

        [NonAction]
        [ApiExplorerSettings(IgnoreApi = true)]
        public override Task<ReviewResponse?> Update(int id, [FromBody] ReviewInsertRequest request)
            => throw new NotSupportedException("Reviews are immutable; delete and create a new one if needed.");

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
