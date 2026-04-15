using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{

    public class VolunteerSkill
    {
        [Key]
        public int VolunteerSkillId { get; set; }

        [Required]
        [ForeignKey(nameof(UserProfile))]
        public int UserProfileId { get; set; }


        [Required]
        [ForeignKey(nameof(Skill))]
        public int SkillId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual UserProfile UserProfile { get; set; } = null!;
        public virtual Skill Skill { get; set; } = null!;
    }
}