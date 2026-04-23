using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class VolunteerApplicationResponse
    {
        public int VolunteerApplicationId { get; set; }
        public int VolunteerJobId { get; set; }
        public string JobTitle { get; set; } = null!;
        public int UserProfileId { get; set; }
        public string ApplicantName { get; set; } = null!;
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public string? CoverLetter { get; set; }
        public string? ResumeUrl { get; set; }
        public string Status { get; set; } = null!;
        public string? RejectionReason { get; set; }
        public bool IsCompleted { get; set; }
        public bool HasReview { get; set; }
        public string? ReviewedByName { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime AppliedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
