using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class AddressResponse
    {
        public int AddressId { get; set; }
        public string? StreetName { get; set; }
        public string? Number { get; set; }
        public string? PostalCode { get; set; }
        public int CityId { get; set; }
        public string CityName { get; set; } = null!;
        public string CountryName { get; set; } = null!;
    }
}
