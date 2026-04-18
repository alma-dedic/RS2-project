using System;

namespace HeartForCharity.Model.Requests
{
    public class DonationsReportRequest
    {
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public int? CampaignId { get; set; }
    }

    public class CampaignsReportRequest
    {
        public string? Status { get; set; }
    }

    public class VolunteersReportRequest
    {
        public int? VolunteerJobId { get; set; }
    }
}
