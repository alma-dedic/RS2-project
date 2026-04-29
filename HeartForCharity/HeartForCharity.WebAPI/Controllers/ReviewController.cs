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

        [Authorize(Roles = Roles.User)]
        [HttpPut("{id}")]
        public override async Task<ReviewResponse?> Update(int id, [FromBody] ReviewInsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
