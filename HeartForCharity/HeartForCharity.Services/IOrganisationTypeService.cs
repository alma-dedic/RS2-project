using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IOrganisationTypeService : ICRUDService<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest> { }
}
