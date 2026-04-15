using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Requests
{
    public class CountryUpsertRequest
    {
        [Required, MaxLength(100)]
        public string Name { get; set; } = null!;
        [MaxLength(10)]
        public string? ISOCode { get; set; }
    }
}
