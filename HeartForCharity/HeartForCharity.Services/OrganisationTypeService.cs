using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class OrganisationTypeService : BaseCRUDService<OrganisationTypeResponse, OrganisationTypeSearchObject, OrganisationType, OrganisationTypeUpsertRequest, OrganisationTypeUpsertRequest>, IOrganisationTypeService
    {
        public OrganisationTypeService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<OrganisationType> ApplyFilter(IQueryable<OrganisationType> query, OrganisationTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(o => o.Name.Contains(search.FTS));
            return query;
        }
    }
}
