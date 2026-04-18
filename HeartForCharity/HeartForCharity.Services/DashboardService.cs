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

            var campaigns = await _context.Campaigns
                .Where(c => c.OrganisationProfileId == orgId && c.DeletedAt == null)
                .ToListAsync();

            var campaignIds = campaigns.Select(c => c.CampaignId).ToList();

            var donations = await _context.Donations
                .Where(d => campaignIds.Contains(d.CampaignId) && d.Status == DonationStatus.Success)
                .ToListAsync();

            var jobIds = await _context.VolunteerJobs
                .Where(j => j.OrganisationProfileId == orgId && j.DeletedAt == null)
                .Select(j => j.VolunteerJobId)
                .ToListAsync();

            var totalVolunteers = await _context.VolunteerApplications
                .Where(a => jobIds.Contains(a.VolunteerJobId) && a.Status == ApplicationStatus.Approved)
                .Select(a => a.UserProfileId)
                .Distinct()
                .CountAsync();

            var sixMonthsAgo = DateTime.UtcNow.AddMonths(-5).Date;
            sixMonthsAgo = new DateTime(sixMonthsAgo.Year, sixMonthsAgo.Month, 1);

            var monthlyDonations = donations
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
                .ToList();

            var recentReviews = await _context.Reviews
                .Include(r => r.UserProfile)
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

            var campaignProgress = campaigns
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
                .ToList();

            return new DashboardResponse
            {
                ActiveCampaigns = campaigns.Count(c => c.Status == CampaignStatus.Active),
                FinishedCampaigns = campaigns.Count(c => c.Status == CampaignStatus.Completed),
                TotalVolunteers = totalVolunteers,
                TotalRaised = donations.Sum(d => d.Amount),
                MonthlyDonations = monthlyDonations,
                RecentReviews = recentReviews,
                CampaignProgress = campaignProgress
            };
        }
    }
}
