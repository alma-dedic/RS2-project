using System;
using System.Collections.Generic;

namespace HeartForCharity.Model.Responses
{
    public class VolunteerJobResponse
    {
        public int VolunteerJobId { get; set; }
        public int OrganisationProfileId { get; set; }
        public string OrganisationName { get; set; } = null!;
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public List<SkillResponse> RequiredSkills { get; set; } = new();
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsRemote { get; set; }
        public int PositionsAvailable { get; set; }
        public int PositionsFilled { get; set; }
        public int PositionsRemaining => PositionsAvailable - PositionsFilled;
        public string Status { get; set; } = null!;
        public int? AddressId { get; set; }
        public int? CityId { get; set; }
        public int? CountryId { get; set; }
        public string? CityName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
