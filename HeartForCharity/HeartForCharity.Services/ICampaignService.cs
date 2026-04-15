using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface ICampaignService : ICRUDService<CampaignResponse, CampaignSearchObject, CampaignInsertRequest, CampaignUpdateRequest>
    {
        Task<CampaignResponse> CompleteAsync(int id);
        Task<CampaignResponse> CancelAsync(int id);
    }
}
