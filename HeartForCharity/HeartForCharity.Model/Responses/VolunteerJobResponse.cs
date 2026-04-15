using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
        public string? Requirements { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsRemote { get; set; }
        public int PositionsAvailable { get; set; }
        public int PositionsFilled { get; set; }
        public int PositionsRemaining => PositionsAvailable - PositionsFilled;
        public string Status { get; set; } = null!;
        public int? AddressId { get; set; }
        public string? CityName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
