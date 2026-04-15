using HeartForCharity.Model.Enums;
using System;

namespace HeartForCharity.Model.Requests
{
    public class CampaignUpdateRequest
    {
        public int? CategoryId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal TargetAmount { get; set; }
        public CampaignStatus Status { get; set; }
    }
}
