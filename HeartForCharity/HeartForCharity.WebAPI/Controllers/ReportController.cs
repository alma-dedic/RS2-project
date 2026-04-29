using HeartForCharity.Model.Constants;
using HeartForCharity.Model.Requests;
using HeartForCharity.WebAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = Roles.Organisation)]
    public class ReportController : ControllerBase
    {
        private readonly IReportService _reportService;

        public ReportController(IReportService reportService)
        {
            _reportService = reportService;
        }

        [HttpPost("donations")]
        public async Task<IActionResult> Donations([FromBody] DonationsReportRequest request)
        {
            var pdf = await _reportService.GenerateDonationsReportAsync(request);
            return File(pdf, "application/pdf", $"donations-report-{DateTime.UtcNow:yyyyMMdd}.pdf");
        }

        [HttpPost("campaigns")]
        public async Task<IActionResult> Campaigns([FromBody] CampaignsReportRequest request)
        {
            var pdf = await _reportService.GenerateCampaignsReportAsync(request);
            return File(pdf, "application/pdf", $"campaigns-report-{DateTime.UtcNow:yyyyMMdd}.pdf");
        }

        [HttpPost("volunteers")]
        public async Task<IActionResult> Volunteers([FromBody] VolunteersReportRequest request)
        {
            var pdf = await _reportService.GenerateVolunteersReportAsync(request);
            return File(pdf, "application/pdf", $"volunteers-report-{DateTime.UtcNow:yyyyMMdd}.pdf");
        }
    }
}
