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
    public class CampaignMediaController : BaseCRUDController<CampaignMediaResponse, CampaignMediaSearchObject, CampaignMediaUpsertRequest, CampaignMediaUpsertRequest>
    {
        public CampaignMediaController(ICampaignMediaService service) : base(service) { }

        [AllowAnonymous]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<CampaignMediaResponse>> Get([FromQuery] CampaignMediaSearchObject? search = null)
            => await base.Get(search);

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override async Task<CampaignMediaResponse?> GetById(int id)
            => await base.GetById(id);
    }
}
