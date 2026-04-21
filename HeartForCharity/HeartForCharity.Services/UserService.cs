using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ICurrentUserService _currentUserService;

        public UserService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(u => u.Username.Contains(search.FTS) || u.Email.Contains(search.FTS));

            if (!string.IsNullOrWhiteSpace(search.UserType) && Enum.TryParse<UserType>(search.UserType, out var userType))
                query = query.Where(u => u.UserType == userType);

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            return query;
        }

        protected override UserResponse MapToResponse(User entity)
        {
            return new UserResponse
            {
                UserId = entity.UserId,
                Username = entity.Username,
                Email = entity.Email,
                UserType = entity.UserType.ToString(),
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt
            };
        }

        protected override User MapInsertToEntity(User entity, UserInsertRequest request)
        {
            entity.Username = request.Username;
            entity.Email = request.Email;
            entity.UserType = (UserType)(int)request.UserType;
            return entity;
        }

        protected override async Task BeforeInsert(User entity, UserInsertRequest request)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsActive = true;
            (entity.PasswordSalt, entity.PasswordHash) = HashPassword(request.Password);
        }

        protected override void MapUpdateToEntity(User entity, UserUpdateRequest request)
        {
            entity.Username = request.Username;
            entity.Email = request.Email;
            entity.UserType = (UserType)(int)request.UserType;
            entity.IsActive = request.IsActive;
        }

        protected override async Task BeforeUpdate(User entity, UserUpdateRequest request)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            if (!string.IsNullOrWhiteSpace(request.NewPassword))
                (entity.PasswordSalt, entity.PasswordHash) = HashPassword(request.NewPassword);
        }

        public async Task<UserResponse> RegisterOrganisationAsync(RegisterOrganisationRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new Exception("Username is already taken.");

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new Exception("Email is already in use.");

            using var transaction = await _context.Database.BeginTransactionAsync();

            var (salt, hash) = HashPassword(request.Password);

            var user = new User
            {
                Username = request.Username,
                Email = request.Email,
                UserType = UserType.Organisation,
                PasswordSalt = salt,
                PasswordHash = hash,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var profile = new OrganisationProfile
            {
                UserId = user.UserId,
                Name = request.OrganisationName,
                Description = request.Description,
                ContactEmail = request.ContactEmail,
                ContactPhone = request.ContactPhone,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.OrganisationProfiles.Add(profile);
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse?> AuthenticateAsync(UserLoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username && u.IsActive);

            if (user == null || !VerifyPassword(request.Password, user.PasswordSalt, user.PasswordHash))
                return null;

            return MapToResponse(user);
        }

        public bool VerifyPassword(string password, string storedSalt, string storedHash)
        {
            var saltBytes = Convert.FromBase64String(storedSalt);
            var computedHash = Convert.ToBase64String(
                Rfc2898DeriveBytes.Pbkdf2(password, saltBytes, 100_000, HashAlgorithmName.SHA256, 32));
            return computedHash == storedHash;
        }

        public async Task<string> GenerateRefreshTokenAsync(int userId)
        {
            var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

            var refreshToken = new RefreshToken
            {
                Token = token,
                UserId = userId,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                CreatedAt = DateTime.UtcNow,
                IsUsed = false,
                IsRevoked = false
            };

            _context.RefreshTokens.Add(refreshToken);
            await _context.SaveChangesAsync();

            return token;
        }

        public async Task<(bool isValid, int userId)> ValidateRefreshTokenAsync(string token)
        {
            var refreshToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == token);

            if (refreshToken == null)
                return (false, 0);

            if (refreshToken.IsRevoked || refreshToken.IsUsed || refreshToken.ExpiresAt < DateTime.UtcNow)
                return (false, 0);

            refreshToken.IsUsed = true;
            refreshToken.IsRevoked = true;
            await _context.SaveChangesAsync();

            return (true, refreshToken.UserId);
        }

        public async Task RevokeRefreshTokenAsync(string token)
        {
            var refreshToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == token);

            if (refreshToken != null)
            {
                refreshToken.IsRevoked = true;
                await _context.SaveChangesAsync();
            }
        }

        public async Task ChangePasswordAsync(ChangePasswordRequest request)
        {
            var user = await _context.Users.FindAsync(_currentUserService.UserId);
            if (user == null)
                throw new UserException("User not found.");

            if (!VerifyPassword(request.CurrentPassword, user.PasswordSalt, user.PasswordHash))
                throw new UserException("Current password is incorrect.");

            (user.PasswordSalt, user.PasswordHash) = HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        public async Task DeactivateAccountAsync()
        {
            var user = await _context.Users.FindAsync(_currentUserService.UserId);
            if (user == null)
                throw new UserException("User not found.");

            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile != null)
            {
                var hasActiveCampaigns = await _context.Campaigns
                    .AnyAsync(c => c.OrganisationProfileId == orgProfile.OrganisationProfileId
                                && c.Status == CampaignStatus.Active);

                if (hasActiveCampaigns)
                    throw new UserException("Cannot delete account with active campaigns. Please complete or cancel them first.");

                var hasActiveJobs = await _context.VolunteerJobs
                    .AnyAsync(j => j.OrganisationProfileId == orgProfile.OrganisationProfileId
                                && j.Status == VolunteerJobStatus.Active);

                if (hasActiveJobs)
                    throw new UserException("Cannot delete account with active volunteer jobs. Please complete or cancel them first.");
            }

            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        private static (string salt, string hash) HashPassword(string password)
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            var hashBytes = Rfc2898DeriveBytes.Pbkdf2(password, saltBytes, 100_000, HashAlgorithmName.SHA256, 32);
            return (Convert.ToBase64String(saltBytes), Convert.ToBase64String(hashBytes));
        }
    }
}
