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
    public class AddressService : BaseCRUDService<AddressResponse, AddressSearchObject, Address, AddressUpsertRequest, AddressUpsertRequest>, IAddressService
    {
        public AddressService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Address> ApplyFilter(IQueryable<Address> query, AddressSearchObject search)
        {
            query = query.Include(a => a.City).ThenInclude(c => c.Country);
            if (search.CityId.HasValue)
                query = query.Where(a => a.CityId == search.CityId);
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(a => a.StreetName!.Contains(search.FTS));
            return query;
        }

        protected override AddressResponse MapToResponse(Address entity)
        {
            return new AddressResponse
            {
                AddressId = entity.AddressId,
                StreetName = entity.StreetName,
                Number = entity.Number,
                PostalCode = entity.PostalCode,
                CityId = entity.CityId,
                CityName = entity.City?.Name ?? string.Empty,
                CountryName = entity.City?.Country?.Name ?? string.Empty
            };
        }
    }
}
