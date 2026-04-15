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
    public class OrganisationTypeController : BaseCRUDController<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest>
    {
        public OrganisationTypeController(IOrganisationTypeService service) : base(service) { }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<OrganisationTypeResponse>> Get([FromQuery] OrganisationTypeSearchObject? search = null)
            => await base.Get(search);

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<OrganisationTypeResponse?> GetById(int id)
            => await base.GetById(id);
    }
}
