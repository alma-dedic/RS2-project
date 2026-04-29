using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ICurrentUserService _currentUserService;

        public DashboardService(HeartForCharityDbContext context, ICurrentUserService currentUserService)
        {
            _context = context;
            _currentUserService = currentUserService;
        }

        public async Task<DashboardResponse> GetDashboardAsync()
        {
            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null)
                throw new UserException("Organisation profile not found.");

            var orgId = orgProfile.OrganisationProfileId;

            var baseCampaigns = _context.Campaigns
                .Where(c => c.OrganisationProfileId == orgId && c.DeletedAt == null);

            var campaignCountsByStatus = await baseCampaigns
                .GroupBy(c => c.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            var activeCampaigns = campaignCountsByStatus
                .FirstOrDefault(x => x.Status == CampaignStatus.Active)?.Count ?? 0;
            var finishedCampaigns = campaignCountsByStatus
                .FirstOrDefault(x => x.Status == CampaignStatus.Completed)?.Count ?? 0;

            var jobIds = _context.VolunteerJobs
                .Where(j => j.OrganisationProfileId == orgId && j.DeletedAt == null)
                .Select(j => j.VolunteerJobId);

            var totalVolunteers = await _context.VolunteerApplications
                .Where(a => jobIds.Contains(a.VolunteerJobId) && a.Status == ApplicationStatus.Approved)
                .Select(a => a.UserProfileId)
                .Distinct()
                .CountAsync();

            var campaignIds = baseCampaigns.Select(c => c.CampaignId);

            var successfulDonations = _context.Donations
                .Where(d => campaignIds.Contains(d.CampaignId) && d.Status == DonationStatus.Success);

            var totalRaised = await successfulDonations.SumAsync(d => (decimal?)d.Amount) ?? 0m;

            var sixMonthsAgo = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc)
                .AddMonths(-5);

            var monthlyDonations = await successfulDonations
                .Where(d => d.DonationDateTime >= sixMonthsAgo)
                .GroupBy(d => new { d.DonationDateTime.Year, d.DonationDateTime.Month })
                .Select(g => new MonthlyDonationItem
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    Total = g.Sum(d => d.Amount),
                    Count = g.Count()
                })
                .OrderBy(m => m.Year).ThenBy(m => m.Month)
                .ToListAsync();

            var recentReviews = await _context.Reviews
                .Where(r => r.OrganisationProfileId == orgId && r.DeletedAt == null)
                .OrderByDescending(r => r.CreatedAt)
                .Take(4)
                .Select(r => new DashboardReviewItem
                {
                    ReviewerName = r.UserProfile != null
                        ? $"{r.UserProfile.FirstName} {r.UserProfile.LastName}"
                        : "Anonymous",
                    ReviewerAvatarUrl = r.UserProfile != null ? r.UserProfile.ProfilePictureUrl : null,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();

            var campaignProgress = await baseCampaigns
                .Where(c => c.Status == CampaignStatus.Active)
                .OrderByDescending(c => c.CurrentAmount)
                .Take(5)
                .Select(c => new CampaignProgressItem
                {
                    CampaignId = c.CampaignId,
                    Title = c.Title,
                    TargetAmount = c.TargetAmount,
                    CurrentAmount = c.CurrentAmount
                })
                .ToListAsync();

            return new DashboardResponse
            {
                ActiveCampaigns = activeCampaigns,
                FinishedCampaigns = finishedCampaigns,
                TotalVolunteers = totalVolunteers,
                TotalRaised = totalRaised,
                MonthlyDonations = monthlyDonations,
                RecentReviews = recentReviews,
                CampaignProgress = campaignProgress
            };
        }
    }
}
