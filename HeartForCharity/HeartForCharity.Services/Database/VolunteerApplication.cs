using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class VolunteerApplication
    {
        [Key]
        public int VolunteerApplicationId { get; set; }

        [Required]
        [ForeignKey(nameof(VolunteerJob))]
        public int VolunteerJobId { get; set; }

        [Required]
        [ForeignKey(nameof(UserProfile))]
        public int UserProfileId { get; set; }

        [MaxLength(4000)]
        public string? CoverLetter { get; set; }

        [MaxLength(500)]
        public string? ResumeUrl { get; set; }

        public ApplicationStatus Status { get; set; } = ApplicationStatus.Pending;

        [MaxLength(500)]
        public string? RejectionReason { get; set; }

        public bool IsCompleted { get; set; } = false;  // volonterski posao završen

        public int? ReviewedByUserId { get; set; }
        public DateTime? ReviewedAt { get; set; }

        public DateTime AppliedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigacijska svojstva
        public virtual VolunteerJob VolunteerJob { get; set; } = null!;
        public virtual UserProfile UserProfile { get; set; } = null!;
        [ForeignKey(nameof(ReviewedByUserId))]
        public virtual User? ReviewedByUser { get; set; }
        public virtual Review? Review { get; set; }
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}