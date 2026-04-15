using HeartForCharity.Model.Enums;

namespace HeartForCharity.Model.Requests
{
    public class UserInsertRequest
    {
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Password { get; set; } = null!;
        public UserType UserType { get; set; }
    }
}
