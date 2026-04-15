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
    public class UserProfileService : BaseCRUDService<UserProfileResponse, UserProfileSearchObject, UserProfile, UserProfileInsertRequest, UserProfileUpdateRequest>, IUserProfileService
    {
        private readonly ICurrentUserService _currentUserService;

        public UserProfileService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<UserProfile> ApplyFilter(IQueryable<UserProfile> query, UserProfileSearchObject search)
        {
            query = query.Include(u => u.Address)
                         .ThenInclude(a => a!.City)
                         .ThenInclude(c => c.Country);
            if (search.UserId.HasValue)
                query = query.Where(u => u.UserId == search.UserId);
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(u => u.FirstName.Contains(search.FTS) || u.LastName.Contains(search.FTS));
            return query;
        }

        protected override UserProfileResponse MapToResponse(UserProfile entity)
        {
            return new UserProfileResponse
            {
                UserProfileId = entity.UserProfileId,
                UserId = entity.UserId,
                FirstName = entity.FirstName,
                LastName = entity.LastName,
                PhoneNumber = entity.PhoneNumber,
                DateOfBirth = entity.DateOfBirth,
                ProfilePictureUrl = entity.ProfilePictureUrl,
                AddressId = entity.AddressId,
                CityName = entity.Address?.City?.Name,
                CountryName = entity.Address?.City?.Country?.Name,
                CreatedAt = entity.CreatedAt
            };
        }

        protected override Task BeforeInsert(UserProfile entity, UserProfileInsertRequest request)
        {
            entity.UserId = _currentUserService.UserId;
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }

        protected override Task BeforeUpdate(UserProfile entity, UserProfileUpdateRequest request)
        {
            if (entity.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only edit your own profile.");

            entity.UpdatedAt = DateTime.UtcNow;
            return Task.CompletedTask;
        }
    }
}
