using HeartForCharity.Model.Responses;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface IDashboardService
    {
        Task<DashboardResponse> GetDashboardAsync();
    }
}
