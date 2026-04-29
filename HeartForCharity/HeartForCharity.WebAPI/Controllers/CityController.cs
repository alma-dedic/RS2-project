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
    public class CityController : BaseCRUDController<CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CityController(ICityService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CityResponse>> Get([FromQuery] CitySearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<CityResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override async Task<CityResponse> Create([FromBody] CityUpsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override async Task<CityResponse?> Update(int id, [FromBody] CityUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
