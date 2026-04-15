using HeartForCharity.Model.Enums;
using System;

namespace HeartForCharity.Model.Requests
{
    public class VolunteerJobUpdateRequest
    {
        public int? CategoryId { get; set; }
        public int? AddressId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public string? Requirements { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsRemote { get; set; } = false;
        public int PositionsAvailable { get; set; }
        public VolunteerJobStatus Status { get; set; }
    }
}
