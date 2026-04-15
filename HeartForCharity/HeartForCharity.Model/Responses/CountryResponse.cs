using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class CountryResponse
    {
        public int CountryId { get; set; }
        public string Name { get; set; } = null!;
        public string? ISOCode { get; set; }

    }
}