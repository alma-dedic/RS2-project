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
    public class CountryService : BaseCRUDService<CountryResponse, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        public CountryService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            return query;
        }
    }
}
