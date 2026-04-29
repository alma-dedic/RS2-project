using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class CampaignResponse
    {
        public int CampaignId { get; set; }
        public int OrganisationProfileId { get; set; }
        public string OrganisationName { get; set; } = null!; 
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; } 
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal TargetAmount { get; set; }
        public decimal CurrentAmount { get; set; } 
        public CampaignStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<CampaignMediaResponse>? CampaignMedias { get; set; }
        public int DonationCount { get; set; }
    }

}