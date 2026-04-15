using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class OrganisationProfileService : BaseCRUDService<OrganisationProfileResponse, OrganisationProfileSearchObject, OrganisationProfile, OrganisationProfileInsertRequest, OrganisationProfileUpdateRequest>, IOrganisationProfileService
    {
        private readonly ICurrentUserService _currentUserService;

        public OrganisationProfileService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<OrganisationProfile> ApplyFilter(IQueryable<OrganisationProfile> query, OrganisationProfileSearchObject search)
        {
            query = query.Include(o => o.OrganisationType)
                         .Include(o => o.Address)
                         .ThenInclude(a => a!.City)
                         .ThenInclude(c => c.Country);
            if (search.OrganisationTypeId.HasValue)
                query = query.Where(o => o.OrganisationTypeId == search.OrganisationTypeId);
            if (search.IsVerified.HasValue)
                query = query.Where(o => o.IsVerified == search.IsVerified);
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(o => o.Name.Contains(search.FTS));
            return query;
        }

        protected override OrganisationProfileResponse MapToResponse(OrganisationProfile entity)
        {
            return new OrganisationProfileResponse
            {
                OrganisationProfileId = entity.OrganisationProfileId,
                UserId = entity.UserId,
                Name = entity.Name,
                Description = entity.Description,
                ContactEmail = entity.ContactEmail,
                ContactPhone = entity.ContactPhone,
                LogoUrl = entity.LogoUrl,
                OrganisationTypeId = entity.OrganisationTypeId,
                OrganisationTypeName = entity.OrganisationType?.Name,
                IsVerified = entity.IsVerified,
                AddressId = entity.AddressId,
                CityName = entity.Address?.City?.Name,
                CountryName = entity.Address?.City?.Country?.Name,
                CreatedAt = entity.CreatedAt
            };
        }

        protected override Task BeforeInsert(OrganisationProfile entity, OrganisationProfileInsertRequest request)
        {
            entity.UserId = _currentUserService.UserId;
            entity.IsVerified = false;
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }

        protected override Task BeforeUpdate(OrganisationProfile entity, OrganisationProfileUpdateRequest request)
        {
            if (entity.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only edit your own organisation profile.");

            entity.UpdatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }

        protected override Task BeforeDelete(OrganisationProfile entity)
        {
            if (entity.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only delete your own organisation profile.");

            return Task.CompletedTask;
        }
    }
}
