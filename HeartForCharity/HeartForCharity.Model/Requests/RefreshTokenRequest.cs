using System.ComponentModel.DataAnnotations;

namespace HeartForCharity.Model.Requests
{
    public class RefreshTokenRequest
    {
        [Required]
        public string RefreshToken { get; set; } = null!;
    }
}
