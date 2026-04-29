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
    public class VolunteerJobController : BaseCRUDController<VolunteerJobResponse, VolunteerJobSearchObject, VolunteerJobInsertRequest, VolunteerJobUpdateRequest>
    {
        private readonly IVolunteerJobService _jobService;

        public VolunteerJobController(IVolunteerJobService service) : base(service)
        {
            _jobService = service;
        }

        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<VolunteerJobResponse>> Get([FromQuery] VolunteerJobSearchObject? search = null)
            => await base.Get(search);

        [HttpGet("{id}")]
        public override async Task<VolunteerJobResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpGet("my")]
        public async Task<HeartForCharity.Model.Responses.PagedResult<VolunteerJobResponse>> GetMy([FromQuery] VolunteerJobSearchObject? search = null)
            => await _jobService.GetMyAsync(search ?? new VolunteerJobSearchObject());

        [Authorize(Roles = Roles.Organisation)]
        [HttpPost]
        public override async Task<VolunteerJobResponse> Create([FromBody] VolunteerJobInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPut("{id}")]
        public override async Task<VolunteerJobResponse?> Update(int id, [FromBody] VolunteerJobUpdateRequest request)
            => await base.Update(id, request);

        [NonAction]
        public override Task<bool> Delete(int id) => throw new NotSupportedException();

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/complete")]
        public async Task<VolunteerJobResponse> Complete(int id)
            => await _jobService.CompleteAsync(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/cancel")]
        public async Task<VolunteerJobResponse> Cancel(int id)
            => await _jobService.CancelAsync(id);
    }
}
