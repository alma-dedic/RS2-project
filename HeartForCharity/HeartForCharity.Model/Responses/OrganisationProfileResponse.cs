using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class OrganisationProfileResponse
    {
        public int OrganisationProfileId { get; set; }
        public int UserId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string? ContactEmail { get; set; }
        public string? ContactPhone { get; set; }
        public string? LogoUrl { get; set; }
        public int? OrganisationTypeId { get; set; }
        public string? OrganisationTypeName { get; set; }
        public bool IsVerified { get; set; }
        public int? AddressId { get; set; }
        public string? CityName { get; set; }
        public string? CountryName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
