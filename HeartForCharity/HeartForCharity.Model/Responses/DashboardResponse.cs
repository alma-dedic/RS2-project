using System;
using System.Collections.Generic;

namespace HeartForCharity.Model.Responses
{
    public class DashboardResponse
    {
        public int ActiveCampaigns { get; set; }
        public int FinishedCampaigns { get; set; }
        public int TotalVolunteers { get; set; }
        public decimal TotalRaised { get; set; }
        public List<MonthlyDonationItem> MonthlyDonations { get; set; } = new();
        public List<DashboardReviewItem> RecentReviews { get; set; } = new();
        public List<CampaignProgressItem> CampaignProgress { get; set; } = new();
    }

    public class MonthlyDonationItem
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public decimal Total { get; set; }
        public int Count { get; set; }
    }

    public class DashboardReviewItem
    {
        public string ReviewerName { get; set; } = null!;
        public string? ReviewerAvatarUrl { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CampaignProgressItem
    {
        public int CampaignId { get; set; }
        public string Title { get; set; } = null!;
        public decimal TargetAmount { get; set; }
        public decimal CurrentAmount { get; set; }
    }
}
