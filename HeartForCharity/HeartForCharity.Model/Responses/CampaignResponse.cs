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
        public string OrganisationName { get; set; } = null!; // iz OrganisationProfile
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; } // iz Category
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal TargetAmount { get; set; }
        public decimal CurrentAmount { get; set; } // prikupljeno do sada
        public CampaignStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Opciono: lista medija (slike/videa)
        public List<CampaignMediaResponse>? CampaignMedias { get; set; }

        // Opciono: sažetak donacija (npr. broj donatora)
        public int DonationCount { get; set; }
    }

}