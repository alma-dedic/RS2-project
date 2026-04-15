using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserResponse?> AuthenticateAsync(UserLoginRequest request);
        bool VerifyPassword(string password, string storedSalt, string storedHash);
        Task<string> GenerateRefreshTokenAsync(int userId);
        Task<(bool isValid, int userId)> ValidateRefreshTokenAsync(string token);
        Task RevokeRefreshTokenAsync(string token);
    }
}
