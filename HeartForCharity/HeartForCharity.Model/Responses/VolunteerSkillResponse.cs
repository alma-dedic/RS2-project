using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class VolunteerSkillResponse
    {
        public int VolunteerSkillId { get; set; }
        public int UserProfileId { get; set; }
        public int SkillId { get; set; }
        public string SkillName { get; set; } = null!;
        public string? SkillDescription { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
