using HeartForCharity.Model.Requests;
using HeartForCharity.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AccountController : ControllerBase
    {
        private readonly IUserService _userService;

        public AccountController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            await _userService.ChangePasswordAsync(request);
            return Ok();
        }

        [Authorize(Roles = "Organisation")]
        [HttpDelete("me")]
        public async Task<IActionResult> DeleteAccount()
        {
            await _userService.DeactivateAccountAsync();
            return Ok();
        }
    }
}
