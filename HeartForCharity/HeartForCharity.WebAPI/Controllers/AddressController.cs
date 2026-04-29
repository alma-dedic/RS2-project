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
    public class AddressController : BaseCRUDController<AddressResponse, AddressSearchObject, AddressUpsertRequest, AddressUpsertRequest>
    {
        public AddressController(IAddressService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<AddressResponse>> Get([FromQuery] AddressSearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<AddressResponse?> GetById(int id)
            => await base.GetById(id);

        [HttpPost("")]
        public override async Task<AddressResponse> Create([FromBody] AddressUpsertRequest request)
            => await base.Create(request);

        [HttpPut("{id}")]
        public override async Task<AddressResponse?> Update(int id, [FromBody] AddressUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
