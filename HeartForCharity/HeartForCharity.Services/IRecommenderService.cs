using HeartForCharity.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IRecommenderService
    {
        Task<List<RecommendedJobResponse>> GetJobRecommendationsAsync();
        Task<List<RecommendedCampaignResponse>> GetCampaignRecommendationsAsync();
    }
}
