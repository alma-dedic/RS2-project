using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class CampaignSearchObject : BaseSearchObject
    {
        public string? Title { get; set; }
        public int? CategoryId { get; set; }
        public string? Status { get; set; }
        public int? OrganisationProfileId { get; set; }
    }
}
