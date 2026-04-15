using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class DonationService : BaseCRUDService<DonationResponse, DonationSearchObject, Donation, DonationInsertRequest, DonationInsertRequest>, IDonationService
    {
        private readonly ICurrentUserService _currentUserService;

        public DonationService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<Donation> ApplyFilter(IQueryable<Donation> query, DonationSearchObject search)
        {
            query = query.Include(d => d.Campaign)
                         .Include(d => d.UserProfile);

            if (search.CampaignId.HasValue)
                query = query.Where(d => d.CampaignId == search.CampaignId);
            if (search.UserProfileId.HasValue)
                query = query.Where(d => d.UserProfileId == search.UserProfileId);
            if (search.DateFrom.HasValue)
                query = query.Where(d => d.DonationDateTime >= search.DateFrom);
            if (search.DateTo.HasValue)
                query = query.Where(d => d.DonationDateTime <= search.DateTo);
            if (!string.IsNullOrWhiteSpace(search.Status) && Enum.TryParse<DonationStatus>(search.Status, out var status))
                query = query.Where(d => d.Status == status);

            return query;
        }

        protected override DonationResponse MapToResponse(Donation entity)
        {
            return new DonationResponse
            {
                DonationId = entity.DonationId,
                CampaignId = entity.CampaignId,
                CampaignTitle = entity.Campaign?.Title ?? string.Empty,
                UserProfileId = entity.UserProfileId,
                DonorName = entity.IsAnonymous
                    ? null
                    : entity.UserProfile != null
                        ? $"{entity.UserProfile.FirstName} {entity.UserProfile.LastName}"
                        : null,
                Amount = entity.Amount,
                IsAnonymous = entity.IsAnonymous,
                PayPalTransactionId = entity.PayPalTransactionId,
                Status = entity.Status.ToString(),
                DonationDateTime = entity.DonationDateTime
            };
        }

        protected override async Task BeforeInsert(Donation entity, DonationInsertRequest request)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            var campaign = await _context.Campaigns.FindAsync(entity.CampaignId);

            if (campaign == null)
                throw new UserException("Campaign not found.");

            if (campaign.Status != CampaignStatus.Active)
                throw new UserException("Donations can only be made to active campaigns.");

            entity.UserProfileId = userProfile.UserProfileId;
            entity.Status = DonationStatus.Pending;
            entity.DonationDateTime = DateTime.UtcNow;
            entity.CreatedAt = DateTime.UtcNow;
        }

        public async Task<PagedResult<DonationResponse>> GetMyAsync(DonationSearchObject search)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            search.UserProfileId = userProfile.UserProfileId;
            return await GetAsync(search);
        }

        public async Task<DonationCreateOrderResponse> CreateOrderAsync(DonationCreateOrderRequest request, string paypalOrderId, string approvalUrl)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            var campaign = await _context.Campaigns.FindAsync(request.CampaignId);

            if (campaign == null)
                throw new UserException("Campaign not found.");

            if (campaign.Status != CampaignStatus.Active)
                throw new UserException("Donations can only be made to active campaigns.");

            var donation = new Donation
            {
                CampaignId    = request.CampaignId,
                UserProfileId = request.IsAnonymous ? null : userProfile.UserProfileId,
                Amount        = request.Amount,
                IsAnonymous   = request.IsAnonymous,
                PayPalOrderId = paypalOrderId,
                Status        = DonationStatus.Pending,
                DonationDateTime = DateTime.UtcNow,
                CreatedAt     = DateTime.UtcNow
            };

            _context.Donations.Add(donation);
            await _context.SaveChangesAsync();

            return new DonationCreateOrderResponse
            {
                OrderId     = paypalOrderId,
                ApprovalUrl = approvalUrl
            };
        }

        public async Task<DonationResponse> CaptureAsync(string paypalOrderId, string captureStatus, string? transactionId)
        {
            var donation = await _context.Donations
                .Include(d => d.Campaign)
                .Include(d => d.UserProfile)
                .FirstOrDefaultAsync(d => d.PayPalOrderId == paypalOrderId);

            if (donation == null)
                throw new UserException("Donation order not found.");

            if (captureStatus == "COMPLETED")
            {
                donation.Status              = DonationStatus.Success;
                donation.PayPalTransactionId = transactionId ?? paypalOrderId;

                var campaign = await _context.Campaigns.FindAsync(donation.CampaignId);
                if (campaign != null)
                {
                    campaign.CurrentAmount += donation.Amount;
                    campaign.UpdatedAt      = DateTime.UtcNow;
                }
            }
            else
            {
                donation.Status = DonationStatus.Failed;
            }

            await _context.SaveChangesAsync();
            return MapToResponse(donation);
        }
    }
}
