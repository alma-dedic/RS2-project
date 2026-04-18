using HeartForCharity.Model.Requests;
using System.Threading.Tasks;

namespace HeartForCharity.WebAPI.Services
{
    public interface IReportService
    {
        Task<byte[]> GenerateDonationsReportAsync(DonationsReportRequest request);
        Task<byte[]> GenerateCampaignsReportAsync(CampaignsReportRequest request);
        Task<byte[]> GenerateVolunteersReportAsync(VolunteersReportRequest request);
    }
}
