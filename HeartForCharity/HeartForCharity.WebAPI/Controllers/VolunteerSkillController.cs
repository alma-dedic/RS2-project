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
    public class VolunteerSkillController : BaseCRUDController<VolunteerSkillResponse, VolunteerSkillSearchObject, VolunteerSkillInsertRequest, VolunteerSkillInsertRequest>
    {
        private readonly IVolunteerSkillService _volunteerSkillService;

        public VolunteerSkillController(IVolunteerSkillService service) : base(service)
        {
            _volunteerSkillService = service;
        }

        [Authorize(Roles = Roles.User)]
        [HttpGet("my")]
        public async Task<PagedResult<VolunteerSkillResponse>> GetMy()
            => await _volunteerSkillService.GetMyAsync();

        [Authorize(Roles = Roles.User)]
        [HttpPost]
        public override async Task<VolunteerSkillResponse> Create([FromBody] VolunteerSkillInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.User)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
