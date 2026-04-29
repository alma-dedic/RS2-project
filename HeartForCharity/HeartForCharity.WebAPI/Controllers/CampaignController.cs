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
    public class CampaignController : BaseCRUDController<CampaignResponse, CampaignSearchObject, CampaignInsertRequest, CampaignUpdateRequest>
    {
        private readonly ICampaignService _campaignService;

        public CampaignController(ICampaignService service) : base(service)
        {
            _campaignService = service;
        }

        [Authorize]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CampaignResponse>> Get([FromQuery] CampaignSearchObject? search = null)
            => await base.Get(search);

        [Authorize(Roles = Roles.Organisation)]
        [HttpGet("my")]
        public async Task<HeartForCharity.Model.Responses.PagedResult<CampaignResponse>> GetMy([FromQuery] CampaignSearchObject? search = null)
            => await _campaignService.GetMyAsync(search ?? new CampaignSearchObject());

        [Authorize]
        [HttpGet("{id}")]
        public override async Task<CampaignResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPost]
        public override async Task<CampaignResponse> Create([FromBody] CampaignInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPut("{id}")]
        public override async Task<CampaignResponse?> Update(int id, [FromBody] CampaignUpdateRequest request)
            => await base.Update(id, request);

        [NonAction]
        public override Task<bool> Delete(int id) => throw new NotSupportedException();

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/complete")]
        public async Task<CampaignResponse> Complete(int id)
            => await _campaignService.CompleteAsync(id);

        [Authorize(Roles = Roles.Organisation)]
        [HttpPatch("{id}/cancel")]
        public async Task<CampaignResponse> Cancel(int id)
            => await _campaignService.CancelAsync(id);
    }
}
