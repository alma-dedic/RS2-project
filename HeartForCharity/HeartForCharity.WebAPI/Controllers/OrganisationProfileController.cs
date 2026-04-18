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
    public class OrganisationProfileController : BaseCRUDController<OrganisationProfileResponse, OrganisationProfileSearchObject, OrganisationProfileInsertRequest, OrganisationProfileUpdateRequest>
    {
        private readonly IOrganisationProfileService _orgService;

        public OrganisationProfileController(IOrganisationProfileService service) : base(service)
        {
            _orgService = service;
        }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<OrganisationProfileResponse>> Get([FromQuery] OrganisationProfileSearchObject? search = null)
            => await base.Get(search);

        [Authorize(Roles = "Organisation")]
        [HttpGet("me")]
        public async Task<OrganisationProfileResponse?> GetMe()
            => await _orgService.GetMeAsync();

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<OrganisationProfileResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = "Organisation")]
        [HttpPost]
        public override async Task<OrganisationProfileResponse> Create([FromBody] OrganisationProfileInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = "Organisation")]
        [HttpPut("{id}")]
        public override async Task<OrganisationProfileResponse?> Update(int id, [FromBody] OrganisationProfileUpdateRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
