using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IUserProfileService : ICRUDService<UserProfileResponse, UserProfileSearchObject, UserProfileInsertRequest, UserProfileUpdateRequest>
    {
        Task<UserProfileResponse?> GetMeAsync();
    }
}
