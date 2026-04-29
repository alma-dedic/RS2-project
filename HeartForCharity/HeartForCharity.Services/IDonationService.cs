using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IDonationService : ICRUDService<DonationResponse, DonationSearchObject, DonationInsertRequest, DonationInsertRequest>
    {
        Task<DonationCreateOrderResponse> CreateOrderAsync(DonationCreateOrderRequest request, string paypalOrderId, string approvalUrl);
        Task<DonationResponse> CaptureAsync(string paypalOrderId, string captureStatus, string? transactionId);
        Task<PagedResult<DonationResponse>> GetMyAsync(DonationSearchObject search);
        Task<PagedResult<DonationResponse>> GetByCampaignAsync(int campaignId);
    }
}
