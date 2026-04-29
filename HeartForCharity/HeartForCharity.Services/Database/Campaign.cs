using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class Campaign
    {
        [Key]
        public int CampaignId { get; set; }

        [Required]
        [ForeignKey(nameof(OrganisationProfile))]
        public int OrganisationProfileId { get; set; }

        [ForeignKey(nameof(Category))]
        public int? CategoryId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = null!;

        [MaxLength(4000)]
        public string? Description { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TargetAmount { get; set; }

        [Required]
        public CampaignStatus Status { get; set; } = CampaignStatus.Active;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentAmount { get; set; } = 0;

        public virtual OrganisationProfile OrganisationProfile { get; set; } = null!;
        public virtual Category? Category { get; set; }
        public virtual ICollection<Donation> Donations { get; set; } = new List<Donation>();
        public virtual ICollection<CampaignMedia> CampaignMedias { get; set; } = new List<CampaignMedia>();
    }
}