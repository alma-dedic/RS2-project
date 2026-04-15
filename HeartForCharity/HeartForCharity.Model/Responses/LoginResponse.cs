using System;

namespace HeartForCharity.Model.Responses
{
    public class LoginResponse
    {
        public string AccessToken { get; set; } = null!;
        public DateTime AccessTokenExpiresAt { get; set; }
        public string RefreshToken { get; set; } = null!;
        public DateTime RefreshTokenExpiresAt { get; set; }
        public UserResponse User { get; set; } = null!;
    }
}
