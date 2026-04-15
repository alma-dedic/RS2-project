using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class CampaignMediaResponse
    {
        public int CampaignMediaId { get; set; }
        public string Url { get; set; } = null!;
        public string MediaType { get; set; } = null!;
        public bool IsCover { get; set; }
    }
}