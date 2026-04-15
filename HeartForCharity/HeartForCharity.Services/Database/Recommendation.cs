using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public enum RecommendationEntityType
    {
        Campaign,
        VolunteerJob
    }

    public class Recommendation
    {
        [Key]
        public int RecommendationId { get; set; }

        [Required]
        [ForeignKey(nameof(UserProfile))]
        public int UserProfileId { get; set; }

        [Required]
        public int EntityId { get; set; }

        [Required]
        public RecommendationEntityType EntityType { get; set; }

        [Required]
        [Column(TypeName = "decimal(5,4)")]
        public decimal Score { get; set; }

        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

        public virtual UserProfile UserProfile { get; set; } = null!;
    }
}