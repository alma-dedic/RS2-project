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
    public class OrganisationTypeController : BaseCRUDController<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest>
    {
        public OrganisationTypeController(IOrganisationTypeService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<OrganisationTypeResponse>> Get([FromQuery] OrganisationTypeSearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<OrganisationTypeResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override async Task<OrganisationTypeResponse> Create([FromBody] OrganisationTypeUpsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override async Task<OrganisationTypeResponse?> Update(int id, [FromBody] OrganisationTypeUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
