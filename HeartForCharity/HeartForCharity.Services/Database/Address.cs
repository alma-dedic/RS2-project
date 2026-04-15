using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services.Database
{
    public class Address
    {
        [Key]
        public int AddressId { get; set; }

        [MaxLength(200)]
        public string? StreetName { get; set; }

        [MaxLength(20)]
        public string? Number { get; set; }

        [MaxLength(20)]
        public string? PostalCode { get; set; }

        [Required]
        [ForeignKey(nameof(City))]
        public int CityId { get; set; }

        public virtual City City { get; set; } = null!;
        public virtual ICollection<UserProfile> UserProfiles { get; set; } = new List<UserProfile>();
        public virtual ICollection<OrganisationProfile> OrganisationProfiles { get; set; } = new List<OrganisationProfile>();
        public virtual ICollection<VolunteerJob> VolunteerJobs { get; set; } = new List<VolunteerJob>();
    }
}
