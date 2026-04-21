using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class VolunteerJobSearchObject : BaseSearchObject
    {
        public int? CategoryId { get; set; }
        public string? Status { get; set; }
        public int? OrganisationProfileId { get; set; }
        public bool? IsRemote { get; set; }
        public int? CityId { get; set; }
        public DateTime? StartDateFrom { get; set; }
        public DateTime? StartDateTo { get; set; }
    }
}
