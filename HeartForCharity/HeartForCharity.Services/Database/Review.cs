using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class Review
    {
        [Key]
        public int ReviewId { get; set; }

        [Required]
        [ForeignKey(nameof(VolunteerApplication))]
        public int VolunteerApplicationId { get; set; }

        [Required]
        [ForeignKey(nameof(OrganisationProfile))]
        public int OrganisationProfileId { get; set; }

        [Required]
        [ForeignKey(nameof(UserProfile))]
        public int UserProfileId { get; set; }

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(2000)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        // Navigacijska svojstva
        public virtual VolunteerApplication VolunteerApplication { get; set; } = null!;
        public virtual OrganisationProfile OrganisationProfile { get; set; } = null!;
        public virtual UserProfile UserProfile { get; set; } = null!;
    }
}