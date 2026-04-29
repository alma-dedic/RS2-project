using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class RecommenderService : IRecommenderService
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ICurrentUserService _currentUserService;

        public RecommenderService(HeartForCharityDbContext context, ICurrentUserService currentUserService)
        {
            _context = context;
            _currentUserService = currentUserService;
        }


        public async Task<List<RecommendedJobResponse>> GetJobRecommendationsAsync()
        {
            var userProfile = await _context.UserProfiles
                .Include(up => up.VolunteerSkills).ThenInclude(vs => vs.Skill)
                .Include(up => up.Address)
                .Include(up => up.VolunteerApplications)
                    .ThenInclude(va => va.VolunteerJob).ThenInclude(vj => vj.Category)
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found.");

            var allSkillIds = await _context.Skills
                .Select(s => s.SkillId)
                .OrderBy(id => id)
                .ToListAsync();


            var userSkillIds = userProfile.VolunteerSkills.Select(vs => vs.SkillId).ToHashSet();
            var userSkillVector = allSkillIds
                .Select(id => userSkillIds.Contains(id) ? 1.0 : 0.0)
                .ToArray();


            var completedCategories = userProfile.VolunteerApplications
                .Where(va => va.IsCompleted && va.VolunteerJob.CategoryId.HasValue)
                .GroupBy(va => va.VolunteerJob.CategoryId!.Value)
                .ToDictionary(g => g.Key, g => g.Count());

            var allCategoryIds = await _context.Categories
                .Select(c => c.CategoryId)
                .OrderBy(id => id)
                .ToListAsync();

            var maxCatCount = completedCategories.Values.Any() ? completedCategories.Values.Max() : 1;
            var userCategoryVector = allCategoryIds
                .Select(id => completedCategories.TryGetValue(id, out var cnt) ? (double)cnt / maxCatCount : 0.0)
                .ToArray();


            var appliedJobIds = userProfile.VolunteerApplications
                .Select(va => va.VolunteerJobId)
                .ToHashSet();

            var activeJobs = await _context.VolunteerJobs
                .Include(j => j.VolunteerJobSkills).ThenInclude(vjs => vjs.Skill)
                .Include(j => j.Category)
                .Include(j => j.Address).ThenInclude(a => a!.City)
                .Include(j => j.OrganisationProfile)
                .Where(j => j.Status == VolunteerJobStatus.Active
                         && j.DeletedAt == null
                         && j.PositionsFilled < j.PositionsAvailable
                         && !appliedJobIds.Contains(j.VolunteerJobId))
                .ToListAsync();

            var userCityId = userProfile.Address?.CityId;
            var scored = new List<(VolunteerJob job, double score, List<string> reasons)>();

            foreach (var job in activeJobs)
            {
                var reasons = new List<string>();
                double score = 0;


                var jobSkillIds = job.VolunteerJobSkills.Select(vjs => vjs.SkillId).ToHashSet();
                var jobSkillVector = allSkillIds
                    .Select(id => jobSkillIds.Contains(id) ? 1.0 : 0.0)
                    .ToArray();
                var skillSim = CosineSimilarity(userSkillVector, jobSkillVector);
                score += skillSim * 0.5;

                if (skillSim > 0)
                {
                    var matched = job.VolunteerJobSkills
                        .Where(vjs => userSkillIds.Contains(vjs.SkillId))
                        .Select(vjs => vjs.Skill?.Name)
                        .Where(n => n != null)
                        .ToList();
                    reasons.Add($"Matches your skills: {string.Join(", ", matched)}");
                }


                if (job.CategoryId.HasValue)
                {
                    var jobCatVector = allCategoryIds
                        .Select(id => id == job.CategoryId.Value ? 1.0 : 0.0)
                        .ToArray();
                    var catSim = CosineSimilarity(userCategoryVector, jobCatVector);
                    score += catSim * 0.3;

                    if (catSim > 0)
                    {
                        var cnt = completedCategories.GetValueOrDefault(job.CategoryId.Value, 0);
                        reasons.Add($"Category \"{job.Category?.Name}\" matches your previous volunteering " +
                                    $"({cnt} completed job{(cnt != 1 ? "s" : "")})");
                    }
                }


                if (job.IsRemote)
                {
                    score += 0.1;
                    reasons.Add("Remote — available from anywhere");
                }
                else if (userCityId.HasValue && job.Address?.CityId == userCityId)
                {
                    score += 0.2;
                    reasons.Add($"In your city ({job.Address?.City?.Name})");
                }


                if (!reasons.Any())
                    reasons.Add("Active volunteer opportunity");

                scored.Add((job, score, reasons));
            }


            var top = scored
                .OrderByDescending(x => x.score)
                .ThenByDescending(x => x.job.CreatedAt)
                .Take(10)
                .ToList();

            await PersistAsync(
                userProfile.UserProfileId,
                RecommendationEntityType.VolunteerJob,
                top.Select(x => (x.job.VolunteerJobId, (decimal)Math.Round(x.score, 4))));

            return top.Select(x => new RecommendedJobResponse
            {
                VolunteerJobId = x.job.VolunteerJobId,
                Title = x.job.Title,
                OrganisationName = x.job.OrganisationProfile?.Name ?? string.Empty,
                CategoryName = x.job.Category?.Name,
                StartDate = x.job.StartDate,
                IsRemote = x.job.IsRemote,
                CityName = x.job.Address?.City?.Name,
                PositionsRemaining = x.job.PositionsAvailable - x.job.PositionsFilled,
                Score = Math.Round(x.score, 4),
                Reasons = x.reasons
            }).ToList();
        }


        public async Task<List<RecommendedCampaignResponse>> GetCampaignRecommendationsAsync()
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found.");

            var successfulDonations = await _context.Donations
                .Include(d => d.Campaign)
                    .ThenInclude(c => c!.Category)
                .Where(d => d.UserProfileId == userProfile.UserProfileId
                         && d.Status == DonationStatus.Success)
                .ToListAsync();

            var allCategoryIds = await _context.Categories
                .Select(c => c.CategoryId)
                .OrderBy(id => id)
                .ToListAsync();

            var activeCampaigns = await _context.Campaigns
                .Include(c => c.Category)
                .Include(c => c.OrganisationProfile)
                .Where(c => c.Status == CampaignStatus.Active && c.DeletedAt == null)
                .ToListAsync();

            List<(Campaign c, double score, List<string> reasons)> scored;

            if (!successfulDonations.Any())
            {
                
                scored = activeCampaigns
                    .OrderByDescending(c => c.CurrentAmount)
                    .Take(10)
                    .Select(c => (c, 0.0, new List<string> { "Popular campaign" }))
                    .ToList();
            }
            else
            {
                
                var categoryFrequency = successfulDonations
                    .Where(d => d.Campaign?.CategoryId.HasValue == true)
                    .GroupBy(d => d.Campaign!.CategoryId!.Value)
                    .ToDictionary(g => g.Key, g => g.Count());

                var maxFreq = categoryFrequency.Values.Any() ? categoryFrequency.Values.Max() : 1;

                
                var userCatVector = allCategoryIds
                    .Select(id => categoryFrequency.TryGetValue(id, out var cnt) ? (double)cnt / maxFreq : 0.0)
                    .ToArray();

                var list = new List<(Campaign, double, List<string>)>();

                foreach (var campaign in activeCampaigns)
                {
                    var reasons = new List<string>();
                    double score = 0;

                    
                    if (campaign.CategoryId.HasValue)
                    {
                        var camCatVector = allCategoryIds
                            .Select(id => id == campaign.CategoryId.Value ? 1.0 : 0.0)
                            .ToArray();
                        var catSim = CosineSimilarity(userCatVector, camCatVector);
                        score += catSim * 0.8;

                        if (catSim > 0)
                        {
                            if (categoryFrequency.TryGetValue(campaign.CategoryId.Value, out var freq))
                                reasons.Add($"You donated to {freq} {campaign.Category?.Name} " +
                                            $"campaign{(freq != 1 ? "s" : "")}");
                            else
                                reasons.Add($"Matches your interest in {campaign.Category?.Name} campaigns");
                        }
                    }

                    
                    var donationsHere = successfulDonations.Count(d => d.CampaignId == campaign.CampaignId);
                    if (donationsHere > 0)
                    {
                        score += Math.Min((double)donationsHere / maxFreq, 1.0) * 0.2;
                        reasons.Add($"You donated to this campaign {donationsHere} " +
                                    $"time{(donationsHere != 1 ? "s" : "")}");
                    }

                    if (!reasons.Any())
                        reasons.Add("Active campaign you might enjoy");

                    list.Add((campaign, score, reasons));
                }

                scored = list
                    .OrderByDescending(x => x.Item2)
                    .Take(10)
                    .ToList();
            }

            await PersistAsync(
                userProfile.UserProfileId,
                RecommendationEntityType.Campaign,
                scored.Select(x => (x.c.CampaignId, (decimal)Math.Round(x.score, 4))));

            return scored.Select(x => new RecommendedCampaignResponse
            {
                CampaignId = x.c.CampaignId,
                Title = x.c.Title,
                OrganisationName = x.c.OrganisationProfile?.Name ?? string.Empty,
                CategoryName = x.c.Category?.Name,
                TargetAmount = x.c.TargetAmount,
                CurrentAmount = x.c.CurrentAmount,
                EndDate = x.c.EndDate,
                Score = Math.Round(x.score, 4),
                Reasons = x.reasons
            }).ToList();
        }

     

        private static double CosineSimilarity(double[] a, double[] b)
        {
            double dot = 0, magA = 0, magB = 0;
            for (int i = 0; i < a.Length; i++)
            {
                dot += a[i] * b[i];
                magA += a[i] * a[i];
                magB += b[i] * b[i];
            }
            return magA == 0 || magB == 0 ? 0.0 : dot / (Math.Sqrt(magA) * Math.Sqrt(magB));
        }

        private async Task PersistAsync(
            int userProfileId,
            RecommendationEntityType type,
            IEnumerable<(int entityId, decimal score)> items)
        {
            var existing = await _context.Recommendations
                .Where(r => r.UserProfileId == userProfileId && r.EntityType == type)
                .ToListAsync();

            _context.Recommendations.RemoveRange(existing);

            _context.Recommendations.AddRange(items.Select(x => new Recommendation
            {
                UserProfileId = userProfileId,
                EntityId = x.entityId,
                EntityType = type,
                Score = x.score,
                GeneratedAt = DateTime.UtcNow
            }));

            await _context.SaveChangesAsync();
        }
    }
}
