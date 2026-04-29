using HeartForCharity.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class Donation
    {
        [Key]
        public int DonationId { get; set; }

        [Required]
        [ForeignKey(nameof(Campaign))]
        public int CampaignId { get; set; }

        [ForeignKey(nameof(UserProfile))]
        public int? UserProfileId { get; set; }  

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public bool IsAnonymous { get; set; } = false;

        [MaxLength(255)]
        public string? PayPalOrderId { get; set; }

        [MaxLength(255)]
        public string? PayPalTransactionId { get; set; }

        public DonationStatus Status { get; set; } = DonationStatus.Pending;

        public DateTime DonationDateTime { get; set; } = DateTime.UtcNow;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual Campaign Campaign { get; set; } = null!;
        public virtual UserProfile? UserProfile { get; set; }
    }
}