using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class VolunteerJob
    {
        [Key]
        public int VolunteerJobId { get; set; }

        [Required]
        [ForeignKey(nameof(OrganisationProfile))]
        public int OrganisationProfileId { get; set; }

        [ForeignKey(nameof(Category))]
        public int? CategoryId { get; set; }

        [ForeignKey(nameof(Address))]
        public int? AddressId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = null!;

        [MaxLength(4000)]
        public string? Description { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        public bool IsRemote { get; set; } = false;

        public int PositionsAvailable { get; set; }
        public int PositionsFilled { get; set; } = 0;

        public VolunteerJobStatus Status { get; set; } = VolunteerJobStatus.Active;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        // Navigacijska svojstva
        public virtual OrganisationProfile OrganisationProfile { get; set; } = null!;
        public virtual Category? Category { get; set; }
        public virtual Address? Address { get; set; }
        public virtual ICollection<VolunteerApplication> VolunteerApplications { get; set; } = new List<VolunteerApplication>();
        public virtual ICollection<VolunteerJobSkill> VolunteerJobSkills { get; set; } = new List<VolunteerJobSkill>();
    }
}