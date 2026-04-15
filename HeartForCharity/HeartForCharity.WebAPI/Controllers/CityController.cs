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
    [Authorize(Roles = "Admin")]
    public class CityController : BaseCRUDController<CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CityController(ICityService service) : base(service) { }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CityResponse>> Get([FromQuery] CitySearchObject? search = null)
            => await base.Get(search);

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<CityResponse?> GetById(int id)
            => await base.GetById(id);
    }
}
