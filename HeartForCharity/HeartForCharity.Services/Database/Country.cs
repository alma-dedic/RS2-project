using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services.Database
{
    public class Country
    {
        [Key]
        public int CountryId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = null!;

        [MaxLength(10)]
        public string? ISOCode { get; set; }

        public virtual ICollection<City> Cities { get; set; } = new List<City>();
    }
}
