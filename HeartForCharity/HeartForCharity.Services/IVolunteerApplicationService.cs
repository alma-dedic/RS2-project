using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IVolunteerApplicationService : ICRUDService<VolunteerApplicationResponse, VolunteerApplicationSearchObject, VolunteerApplicationInsertRequest, VolunteerApplicationInsertRequest>
    {
        Task<VolunteerApplicationResponse> ApproveAsync(int id);
        Task<VolunteerApplicationResponse> RejectAsync(int id, ApplicationRejectRequest request);
        Task<PagedResult<VolunteerApplicationResponse>> GetMyAsync(VolunteerApplicationSearchObject search);
    }
}
