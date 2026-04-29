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
    public class SkillController : BaseCRUDController<SkillResponse, SkillSearchObject, SkillUpsertRequest, SkillUpsertRequest>
    {
        public SkillController(ISkillService service) : base(service) { }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<SkillResponse>> Get([FromQuery] SkillSearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<SkillResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override async Task<SkillResponse> Create([FromBody] SkillUpsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override async Task<SkillResponse?> Update(int id, [FromBody] SkillUpsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
