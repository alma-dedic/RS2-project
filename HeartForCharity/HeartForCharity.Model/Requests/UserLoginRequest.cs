using System.ComponentModel.DataAnnotations;

namespace HeartForCharity.Model.Requests
{
    public class UserLoginRequest
    {
        [Required]
        public string Username { get; set; } = null!;

        [Required]
        public string Password { get; set; } = null!;
    }
}
