using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services.CampaignStateMachine
{
    public class BaseCampaignState
    {
        protected readonly HeartForCharityDbContext _context;
        protected readonly ICurrentUserService _currentUserService;
        protected readonly IServiceProvider _serviceProvider;

        public BaseCampaignState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
        {
            _context = context;
            _currentUserService = currentUserService;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<CampaignResponse> CompleteAsync(int id)
            => throw new UserException("Action not allowed in current campaign status.");

        public virtual Task<CampaignResponse> CancelAsync(int id)
            => throw new UserException("Action not allowed in current campaign status.");

        public BaseCampaignState GetState(CampaignStatus status) => status switch
        {
            CampaignStatus.Active    => _serviceProvider.GetRequiredService<ActiveCampaignState>(),
            CampaignStatus.Completed => _serviceProvider.GetRequiredService<CompletedCampaignState>(),
            CampaignStatus.Cancelled => _serviceProvider.GetRequiredService<CancelledCampaignState>(),
            _ => throw new UserException($"Unknown campaign status: {status}")
        };

        protected static CampaignResponse MapToResponse(Campaign entity) => new()
        {
            CampaignId            = entity.CampaignId,
            OrganisationProfileId = entity.OrganisationProfileId,
            OrganisationName      = entity.OrganisationProfile?.Name ?? string.Empty,
            CategoryId            = entity.CategoryId,
            CategoryName          = entity.Category?.Name,
            Title                 = entity.Title,
            Description           = entity.Description,
            StartDate             = entity.StartDate,
            EndDate               = entity.EndDate,
            TargetAmount          = entity.TargetAmount,
            CurrentAmount         = entity.CurrentAmount,
            Status                = entity.Status,
            CreatedAt             = entity.CreatedAt,
            UpdatedAt             = entity.UpdatedAt,
            DonationCount         = entity.Donations?.Count ?? 0,
            CampaignMedias        = entity.CampaignMedias?.Select(m => new CampaignMediaResponse
            {
                CampaignMediaId = m.CampaignMediaId,
                Url             = m.Url,
                MediaType       = m.MediaType.ToString(),
                IsCover         = m.IsCover
            }).ToList()
        };
    }
}
