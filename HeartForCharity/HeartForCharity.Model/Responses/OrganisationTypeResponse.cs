using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class OrganisationTypeResponse
    {
        public int OrganisationTypeId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }
}
