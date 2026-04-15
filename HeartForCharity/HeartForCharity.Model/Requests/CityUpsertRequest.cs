using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required, MaxLength(100)]
        public string Name { get; set; } = null!;
        [Required]
        public int CountryId { get; set; }
    }
}
