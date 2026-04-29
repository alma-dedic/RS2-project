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
    public class UserProfileController : BaseCRUDController<UserProfileResponse, UserProfileSearchObject, UserProfileInsertRequest, UserProfileUpdateRequest>
    {
        private readonly IUserProfileService _userProfileService;

        public UserProfileController(IUserProfileService service) : base(service)
        {
            _userProfileService = service;
        }

        [Authorize(Roles = Roles.User)]
        [HttpGet("me")]
        public async Task<ActionResult<UserProfileResponse?>> GetMe()
        {
            var profile = await _userProfileService.GetMeAsync();
            if (profile == null) return NotFound();
            return Ok(profile);
        }

        [Authorize(Roles = Roles.User)]
        [HttpPost]
        public override async Task<UserProfileResponse> Create([FromBody] UserProfileInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = Roles.User)]
        [HttpPut("{id}")]
        public override async Task<UserProfileResponse?> Update(int id, [FromBody] UserProfileUpdateRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
