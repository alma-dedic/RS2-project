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
    public class VolunteerApplicationController : BaseCRUDController<VolunteerApplicationResponse, VolunteerApplicationSearchObject, VolunteerApplicationInsertRequest, VolunteerApplicationInsertRequest>
    {
        private readonly IVolunteerApplicationService _applicationService;

        public VolunteerApplicationController(IVolunteerApplicationService service) : base(service)
        {
            _applicationService = service;
        }

        [Authorize(Roles = Roles.OrganisationOrAdmin)]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<VolunteerApplicationResponse>> Get([FromQuery] VolunteerApplicationSearchObject? search = null)
            => await base.Get(search);

        [Authorize(Roles = Roles.User)]
        [HttpGet("user")]
        public async Task<HeartForCharity.Model.Responses.PagedResult<VolunteerApplicationResponse>> GetUser([FromQuery] VolunteerApplicationSearchObject? search = null)
            => await _applicationService.GetMyAsync(search ?? new VolunteerApplicationSearchObject());

        [Authorize(Roles = Roles.All)]
        [HttpGet("{id}")]
        public override async Task<VolunteerApplicationResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.User)]
        [HttpPost]
        public override async Task<VolunteerApplicationResponse> Create([FromBody] VolunteerApplicationInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPut("{id}")]
        public override async Task<VolunteerApplicationResponse?> Update(int id, [FromBody] VolunteerApplicationInsertRequest request)
            => await base.Update(id, request);

        [NonAction]
        public override Task<bool> Delete(int id) => throw new NotSupportedException();

        [Authorize(Roles = Roles.User)]
        [HttpPatch("{id}/withdraw")]
        public async Task<bool> Withdraw(int id)
            => await _applicationService.WithdrawAsync(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/approve")]
        public async Task<VolunteerApplicationResponse> Approve(int id)
            => await _applicationService.ApproveAsync(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/reject")]
        public async Task<VolunteerApplicationResponse> Reject(int id, [FromBody] ApplicationRejectRequest request)
            => await _applicationService.RejectAsync(id, request);
    }
}
