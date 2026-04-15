using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class ReviewResponse
    {
        public int ReviewId { get; set; }
        public int VolunteerApplicationId { get; set; }
        public int OrganisationProfileId { get; set; }
        public string OrganisationName { get; set; } = null!;
        public int UserProfileId { get; set; }
        public string ReviewerName { get; set; } = null!;
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
