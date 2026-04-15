using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly IConfiguration _configuration;

        public UserController(IUserService service, IConfiguration configuration) : base(service)
        {
            _userService = service;
            _configuration = configuration;
        }

        [AllowAnonymous]
        [HttpPost]
        public override async Task<UserResponse> Create([FromBody] UserInsertRequest request)
            => await base.Create(request);

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] UserLoginRequest request)
        {
            var user = await _userService.AuthenticateAsync(request);

            if (user == null)
                return Unauthorized();

            var accessToken = GenerateAccessToken(user);
            var refreshToken = await _userService.GenerateRefreshTokenAsync(user.UserId);
            var refreshTokenExpiry = DateTime.UtcNow.AddDays(7);
            var accessTokenExpiry = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpiryMinutes"]!));

            return Ok(new LoginResponse
            {
                AccessToken = accessToken,
                AccessTokenExpiresAt = accessTokenExpiry,
                RefreshToken = refreshToken,
                RefreshTokenExpiresAt = refreshTokenExpiry,
                User = user
            });
        }

        [AllowAnonymous]
        [HttpPost("refresh")]
        public async Task<ActionResult<LoginResponse>> Refresh([FromBody] RefreshTokenRequest request)
        {
            var (isValid, userId) = await _userService.ValidateRefreshTokenAsync(request.RefreshToken);

            if (!isValid)
                return Unauthorized("Invalid or expired refresh token");

            var user = await _userService.GetByIdAsync(userId);

            if (user == null)
                return Unauthorized();

            var accessToken = GenerateAccessToken(user);
            var newRefreshToken = await _userService.GenerateRefreshTokenAsync(userId);
            var refreshTokenExpiry = DateTime.UtcNow.AddDays(7);
            var accessTokenExpiry = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpiryMinutes"]!));

            return Ok(new LoginResponse
            {
                AccessToken = accessToken,
                AccessTokenExpiresAt = accessTokenExpiry,
                RefreshToken = newRefreshToken,
                RefreshTokenExpiresAt = refreshTokenExpiry,
                User = user
            });
        }

        [AllowAnonymous]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            await _userService.RevokeRefreshTokenAsync(request.RefreshToken);
            return Ok();
        }

        private string GenerateAccessToken(UserResponse user)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expiryMinutes = int.Parse(_configuration["Jwt:ExpiryMinutes"]!);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.UserType)
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
