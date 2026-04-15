using HeartForCharity.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class Notification
    {
        [Key]
        public int NotificationId { get; set; }

        [Required]
        [ForeignKey(nameof(UserProfile))]
        public int UserProfileId { get; set; }  

        [ForeignKey(nameof(VolunteerApplication))]
        public int? VolunteerApplicationId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = null!;

        [Required]
        [MaxLength(2000)]
        public string Message { get; set; } = null!;

        public NotificationType Type { get; set; } = NotificationType.General;
        public bool IsRead { get; set; } = false;

        public DateTime SentDateTime { get; set; } = DateTime.UtcNow;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigacijska svojstva
        public virtual UserProfile UserProfile { get; set; } = null!;
        public virtual VolunteerApplication? VolunteerApplication { get; set; }
    }
}