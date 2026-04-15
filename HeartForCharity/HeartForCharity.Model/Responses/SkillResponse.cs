using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class SkillResponse
    {
        public int SkillId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }
}
