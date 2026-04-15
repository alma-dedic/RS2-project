using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class OrganisationProfileSearchObject : BaseSearchObject
    {
        public int? OrganisationTypeId { get; set; }
        public bool? IsVerified { get; set; }
    }
}
