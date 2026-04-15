using HeartForCharity.Model.Enums;

namespace HeartForCharity.Model.Requests
{
    public class UserUpdateRequest
    {
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public UserType UserType { get; set; }
        public bool IsActive { get; set; }

        /// <summary>Leave null to keep the existing password unchanged</summary>
        public string? NewPassword { get; set; }
    }
}
