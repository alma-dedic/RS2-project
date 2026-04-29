using System;
using System.Collections.Generic;

namespace HeartForCharity.Model.Responses
{
    public class RecommendedJobResponse
    {
        public int VolunteerJobId { get; set; }
        public string Title { get; set; } = null!;
        public string OrganisationName { get; set; } = null!;
        public string? CategoryName { get; set; }
        public DateTime? StartDate { get; set; }
        public bool IsRemote { get; set; }
        public string? CityName { get; set; }
        public int PositionsRemaining { get; set; }
        public double Score { get; set; }
        public List<string> Reasons { get; set; } = new();
    }
}
