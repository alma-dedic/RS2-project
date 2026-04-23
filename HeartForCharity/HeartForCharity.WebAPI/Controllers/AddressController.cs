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
    public class AddressController : BaseCRUDController<AddressResponse, AddressSearchObject, AddressUpsertRequest, AddressUpsertRequest>
    {
        public AddressController(IAddressService service) : base(service) { }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<AddressResponse>> Get([FromQuery] AddressSearchObject? search = null)
            => await base.Get(search);

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<AddressResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize]
        [HttpPost("")]
        public override async Task<AddressResponse> Create([FromBody] AddressUpsertRequest request)
            => await base.Create(request);

        [Authorize]
        [HttpPut("{id}")]
        public override async Task<AddressResponse?> Update(int id, [FromBody] AddressUpsertRequest request)
            => await base.Update(id, request);
    }
}
