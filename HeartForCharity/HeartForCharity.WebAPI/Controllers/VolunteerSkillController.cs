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
        public VolunteerSkillController(IVolunteerSkillService service) : base(service) { }

        [Authorize(Roles = "User")]
        [HttpPost]
        public override async Task<VolunteerSkillResponse> Create([FromBody] VolunteerSkillInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = "User")]
        [HttpPut("{id}")]
        public override async Task<VolunteerSkillResponse?> Update(int id, [FromBody] VolunteerSkillInsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = "User")]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
