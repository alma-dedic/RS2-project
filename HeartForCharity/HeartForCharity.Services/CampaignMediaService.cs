using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class CampaignMediaService : BaseCRUDService<CampaignMediaResponse, CampaignMediaSearchObject, CampaignMedia, CampaignMediaUpsertRequest, CampaignMediaUpsertRequest>, ICampaignMediaService
    {
        private readonly ICurrentUserService _currentUserService;

        public CampaignMediaService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<CampaignMedia> ApplyFilter(IQueryable<CampaignMedia> query, CampaignMediaSearchObject search)
        {
            if (search.CampaignId.HasValue)
                query = query.Where(m => m.CampaignId == search.CampaignId);
            return query;
        }

        protected override async Task BeforeInsert(CampaignMedia entity, CampaignMediaUpsertRequest request)
        {
            await VerifyCampaignOwnership(entity.CampaignId);
        }

        protected override async Task BeforeUpdate(CampaignMedia entity, CampaignMediaUpsertRequest request)
        {
            await VerifyCampaignOwnership(entity.CampaignId);
        }

        protected override async Task BeforeDelete(CampaignMedia entity)
        {
            await VerifyCampaignOwnership(entity.CampaignId);
        }

        private async Task VerifyCampaignOwnership(int campaignId)
        {
            var campaign = await _context.Campaigns
                .Include(c => c.OrganisationProfile)
                .FirstOrDefaultAsync(c => c.CampaignId == campaignId);

            if (campaign == null || campaign.OrganisationProfile == null ||
                campaign.OrganisationProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only manage media for your own campaigns.");
        }
    }
}
