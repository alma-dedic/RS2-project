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
    [Authorize(Roles = "Organisation")]
    public class VolunteerJobController : BaseCRUDController<VolunteerJobResponse, VolunteerJobSearchObject, VolunteerJobInsertRequest, VolunteerJobUpdateRequest>
    {
        private readonly IVolunteerJobService _jobService;

        public VolunteerJobController(IVolunteerJobService service) : base(service)
        {
            _jobService = service;
        }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<VolunteerJobResponse>> Get([FromQuery] VolunteerJobSearchObject? search = null)
            => await base.Get(search);

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<VolunteerJobResponse?> GetById(int id)
            => await base.GetById(id);

        [HttpPatch("{id}/complete")]
        public async Task<VolunteerJobResponse> Complete(int id)
            => await _jobService.CompleteAsync(id);

        [HttpPatch("{id}/cancel")]
        public async Task<VolunteerJobResponse> Cancel(int id)
            => await _jobService.CancelAsync(id);
    }
}
