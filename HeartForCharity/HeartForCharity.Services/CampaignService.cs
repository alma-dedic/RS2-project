using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.CampaignStateMachine;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class CampaignService : BaseCRUDService<CampaignResponse, CampaignSearchObject, Campaign, CampaignInsertRequest, CampaignUpdateRequest>, ICampaignService
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly BaseCampaignState _baseState;

        public CampaignService(
            HeartForCharityDbContext context,
            IMapper mapper,
            ICurrentUserService currentUserService,
            BaseCampaignState baseState)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
            _baseState = baseState;
        }

        public async Task<CampaignResponse> CompleteAsync(int id)
        {
            var campaign = await _context.Campaigns.FindAsync(id);
            if (campaign == null)
                throw new UserException("Campaign not found.");

            var state = _baseState.GetState(campaign.Status);
            return await state.CompleteAsync(id);
        }

        public async Task<CampaignResponse> CancelAsync(int id)
        {
            var campaign = await _context.Campaigns.FindAsync(id);
            if (campaign == null)
                throw new UserException("Campaign not found.");

            var state = _baseState.GetState(campaign.Status);
            return await state.CancelAsync(id);
        }

        public async Task<PagedResult<CampaignResponse>> GetMyAsync(CampaignSearchObject search)
        {
            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null)
                throw new UserException("Organisation profile not found for current user.");

            search.OrganisationProfileId = orgProfile.OrganisationProfileId;
            return await GetAsync(search);
        }

        public override async Task<CampaignResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Campaigns
                .Include(c => c.OrganisationProfile)
                .Include(c => c.Category)
                .Include(c => c.CampaignMedias)
                .Include(c => c.Donations)
                .Where(c => c.DeletedAt == null)
                .FirstOrDefaultAsync(c => c.CampaignId == id);

            if (entity == null) return null;
            return MapToResponse(entity);
        }

        protected override IQueryable<Campaign> ApplyFilter(IQueryable<Campaign> query, CampaignSearchObject search)
        {
            query = query.Where(c => c.DeletedAt == null)
                         .Include(c => c.OrganisationProfile)
                         .Include(c => c.Category)
                         .Include(c => c.CampaignMedias)
                         .Include(c => c.Donations);

            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Title.Contains(search.FTS) || c.Description!.Contains(search.FTS));
            if (!string.IsNullOrWhiteSpace(search.Title))
                query = query.Where(c => c.Title.Contains(search.Title));
            if (search.CategoryId.HasValue)
                query = query.Where(c => c.CategoryId == search.CategoryId);
            if (!string.IsNullOrWhiteSpace(search.Status) && Enum.TryParse<CampaignStatus>(search.Status, out var status))
                query = query.Where(c => c.Status == status);
            if (search.OrganisationProfileId.HasValue)
                query = query.Where(c => c.OrganisationProfileId == search.OrganisationProfileId);

            query = query.OrderByDescending(c => c.CreatedAt);

            return query;
        }

        protected override CampaignResponse MapToResponse(Campaign entity)
        {
            return new CampaignResponse
            {
                CampaignId = entity.CampaignId,
                OrganisationProfileId = entity.OrganisationProfileId,
                OrganisationName = entity.OrganisationProfile?.Name ?? string.Empty,
                CategoryId = entity.CategoryId,
                CategoryName = entity.Category?.Name,
                Title = entity.Title,
                Description = entity.Description,
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                TargetAmount = entity.TargetAmount,
                CurrentAmount = entity.CurrentAmount,
                Status = entity.Status,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
                DonationCount = entity.Donations?.Count(d => d.Status == DonationStatus.Success) ?? 0,
                CampaignMedias = entity.CampaignMedias?.Select(m => new CampaignMediaResponse
                {
                    CampaignMediaId = m.CampaignMediaId,
                    Url = m.Url,
                    MediaType = m.MediaType.ToString(),
                    IsCover = m.IsCover
                }).ToList()
            };
        }

        protected override async Task BeforeInsert(Campaign entity, CampaignInsertRequest request)
        {
            var orgProfile = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);

            if (orgProfile == null)
                throw new UserException("Organisation profile not found for current user.");

            entity.OrganisationProfileId = orgProfile.OrganisationProfileId;
            entity.Status = CampaignStatus.Active;
            entity.CurrentAmount = 0;
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(Campaign entity, CampaignUpdateRequest request)
        {
            var orgProfile = await _context.OrganisationProfiles.FindAsync(entity.OrganisationProfileId);

            if (orgProfile == null || orgProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only edit your own campaigns.");

            if (entity.Status != CampaignStatus.Active)
                throw new UserException("You can only edit active campaigns.");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeDelete(Campaign entity)
        {
            var orgProfile = await _context.OrganisationProfiles.FindAsync(entity.OrganisationProfileId);

            if (orgProfile == null || orgProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only delete your own campaigns.");

            if (entity.Status != CampaignStatus.Active)
                throw new UserException("You can only delete active campaigns.");

            var donationCount = await _context.Donations.CountAsync(d => d.CampaignId == entity.CampaignId);
            if (donationCount > 0)
                throw new UserException("Cannot delete a campaign that has donations.");
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<Campaign>().FindAsync(id);
            if (entity == null) return false;

            await BeforeDelete(entity);

            entity.DeletedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
