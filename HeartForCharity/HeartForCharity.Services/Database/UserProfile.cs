using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Net;

namespace HeartForCharity.Services.Database
{
    public class UserProfile
    {
        [Key]
        public int UserProfileId { get; set; }

        [Required]
        [ForeignKey(nameof(User))]
        public int UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string LastName { get; set; } = null!;

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public DateTime? DateOfBirth { get; set; }

        [MaxLength(500)]
        public string? ProfilePictureUrl { get; set; }

        [ForeignKey(nameof(Address))]
        public int? AddressId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        // Navigacijska svojstva
        public virtual User User { get; set; } = null!;
        public virtual Address? Address { get; set; }
        public virtual ICollection<VolunteerSkill> VolunteerSkills { get; set; } = new List<VolunteerSkill>();
        public virtual ICollection<Donation> Donations { get; set; } = new List<Donation>();
        public virtual ICollection<VolunteerApplication> VolunteerApplications { get; set; } = new List<VolunteerApplication>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<Recommendation> Recommendations { get; set; } = new List<Recommendation>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>(); // Dodato
    }
}