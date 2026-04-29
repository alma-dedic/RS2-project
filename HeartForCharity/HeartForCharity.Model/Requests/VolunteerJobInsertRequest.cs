using System;
using System.Collections.Generic;

namespace HeartForCharity.Model.Requests
{
    public class VolunteerJobInsertRequest
    {
        public int? CategoryId { get; set; }
        public int? AddressId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public List<int> SkillIds { get; set; } = new();
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsRemote { get; set; } = false;
        public int PositionsAvailable { get; set; }
    }
}
