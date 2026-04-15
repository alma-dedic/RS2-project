using HeartForCharity.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class CampaignMedia
    {
        [Key]
        public int CampaignMediaId { get; set; }

        [Required]
        [ForeignKey(nameof(Campaign))]
        public int CampaignId { get; set; }

        [Required]
        [MaxLength(500)]
        public string Url { get; set; } = null!;

        public MediaType MediaType { get; set; } = MediaType.Image;
        public bool IsCover { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual Campaign Campaign { get; set; } = null!;
    }


}
