using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class CityService : BaseCRUDService<CityResponse, CitySearchObject, City, CityUpsertRequest, CityUpsertRequest>, ICityService
    {
        public CityService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject search)
        {
            query = query.Include(c => c.Country);
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));
            if (search.CountryId.HasValue)
                query = query.Where(c => c.CountryId == search.CountryId);
            return query.OrderByDescending(c => c.CityId);
        }

        protected override CityResponse MapToResponse(City entity)
        {
            return new CityResponse
            {
                CityId = entity.CityId,
                Name = entity.Name,
                CountryId = entity.CountryId,
                CountryName = entity.Country?.Name ?? string.Empty
            };
        }

        protected override async Task BeforeDelete(City entity)
        {
            var inUse = await _context.Addresses.AnyAsync(a => a.CityId == entity.CityId);

            if (inUse)
                throw new UserException("Cannot delete this city because it is in use.");
        }
    }
}
