using System;
using System.Collections.Generic;

namespace HeartForCharity.Model.Responses
{
    public class RecommendedCampaignResponse
    {
        public int CampaignId { get; set; }
        public string Title { get; set; } = null!;
        public string OrganisationName { get; set; } = null!;
        public string? CategoryName { get; set; }
        public decimal TargetAmount { get; set; }
        public decimal CurrentAmount { get; set; }
        public DateTime? EndDate { get; set; }
        public double Score { get; set; }
        public List<string> Reasons { get; set; } = new();
    }
}
