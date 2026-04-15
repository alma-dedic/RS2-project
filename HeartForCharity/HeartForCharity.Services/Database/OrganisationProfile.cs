using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Net;

namespace HeartForCharity.Services.Database
{
    public class OrganisationProfile
    {
        [Key]
        public int OrganisationProfileId { get; set; }

        [Required]
        [ForeignKey(nameof(User))]
        public int UserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = null!;

        [MaxLength(2000)]
        public string? Description { get; set; }

        [MaxLength(255)]
        [EmailAddress]
        public string? ContactEmail { get; set; }

        [MaxLength(20)]
        public string? ContactPhone { get; set; }

        [ForeignKey(nameof(Address))]
        public int? AddressId { get; set; }

        [MaxLength(500)]
        public string? LogoUrl { get; set; }

        [ForeignKey(nameof(OrganisationType))]
        public int? OrganisationTypeId { get; set; }

        public bool IsVerified { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        // Navigacijska svojstva
        public virtual User User { get; set; } = null!;
        public virtual Address? Address { get; set; }
        public virtual OrganisationType? OrganisationType { get; set; }
        public virtual ICollection<Campaign> Campaigns { get; set; } = new List<Campaign>();
        public virtual ICollection<VolunteerJob> VolunteerJobs { get; set; } = new List<VolunteerJob>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
}