using System;

namespace HeartForCharity.Model.Requests
{
    public class UserProfileUpdateRequest
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? ProfilePictureUrl { get; set; }
        public int? AddressId { get; set; }
    }
}
