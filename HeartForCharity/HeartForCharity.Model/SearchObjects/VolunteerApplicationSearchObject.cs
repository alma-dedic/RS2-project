using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class VolunteerApplicationSearchObject : BaseSearchObject
    {
        public int? VolunteerJobId { get; set; }
        public int? UserProfileId { get; set; }
        public string? Status { get; set; }
        public bool? IsCompleted { get; set; }
    }
}
