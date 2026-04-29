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
    public class CountryController : BaseCRUDController<CountryResponse, CountrySearchObject, CountryUpsertRequest, CountryUpsertRequest>
    {
        public CountryController(ICountryService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CountryResponse>> Get([FromQuery] CountrySearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<CountryResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override async Task<CountryResponse> Create([FromBody] CountryUpsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override async Task<CountryResponse?> Update(int id, [FromBody] CountryUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
