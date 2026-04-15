using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class CityResponse
    {
        public int CityId { get; set; }
        public string Name { get; set; } = null!;
        public int CountryId { get; set; }
        public string CountryName { get; set; } = null!;
    }
}
