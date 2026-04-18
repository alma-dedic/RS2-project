using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IVolunteerJobService : ICRUDService<VolunteerJobResponse, VolunteerJobSearchObject, VolunteerJobInsertRequest, VolunteerJobUpdateRequest>
    {
        Task<VolunteerJobResponse> CompleteAsync(int id);
        Task<VolunteerJobResponse> CancelAsync(int id);
        Task<PagedResult<VolunteerJobResponse>> GetMyAsync(VolunteerJobSearchObject search);
    }
}
