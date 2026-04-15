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
        public string? CoverLetter { get; set; }
        public string? ResumeUrl { get; set; }
        public string Status { get; set; } = null!;
        public string? RejectionReason { get; set; }
        public bool IsCompleted { get; set; }
        public DateTime AppliedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
