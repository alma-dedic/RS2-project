using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Requests
{
    public class AddressUpsertRequest
    {
        [MaxLength(200)]
        public string? StreetName { get; set; }
        [MaxLength(20)]
        public string? Number { get; set; }
        [MaxLength(20)]
        public string? PostalCode { get; set; }
        [Required]
        public int CityId { get; set; }
    }
}
