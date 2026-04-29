using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class DonationResponse
    {
        public int DonationId { get; set; }
        public int CampaignId { get; set; }
        public string CampaignTitle { get; set; } = null!;
        public int? UserProfileId { get; set; }
        public string? DonorName { get; set; } 
        public string? DonorAvatarUrl { get; set; } 
        public decimal Amount { get; set; }
        public bool IsAnonymous { get; set; }
        public string? PayPalTransactionId { get; set; }
        public string Status { get; set; } = null!;
        public bool IsPaid { get; set; }
        public DateTime DonationDateTime { get; set; }
    }
}
