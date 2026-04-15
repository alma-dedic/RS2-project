using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        public UserService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

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
            using var hmac = new HMACSHA256(saltBytes);
            var computedHash = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(password)));
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

        private static (string salt, string hash) HashPassword(string password)
        {
            using var hmac = new HMACSHA256();
            var salt = Convert.ToBase64String(hmac.Key);
            var hash = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(password)));
            return (salt, hash);
        }
    }
}
