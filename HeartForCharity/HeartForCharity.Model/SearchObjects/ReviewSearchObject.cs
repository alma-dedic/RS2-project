using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? OrganisationProfileId { get; set; }
        public int? UserProfileId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
    }
}
