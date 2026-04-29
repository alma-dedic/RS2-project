using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class VolunteerJobSkill
    {
        [Key]
        public int VolunteerJobSkillId { get; set; }

        [Required]
        [ForeignKey(nameof(VolunteerJob))]
        public int VolunteerJobId { get; set; }

        [Required]
        [ForeignKey(nameof(Skill))]
        public int SkillId { get; set; }

        public virtual VolunteerJob VolunteerJob { get; set; } = null!;
        public virtual Skill Skill { get; set; } = null!;
    }
}
