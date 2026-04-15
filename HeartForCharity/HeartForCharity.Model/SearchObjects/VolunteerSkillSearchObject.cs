using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class VolunteerSkillSearchObject : BaseSearchObject
    {
        public int? UserProfileId { get; set; }
        public int? SkillId { get; set; }
    }
}
