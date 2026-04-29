using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
using HeartForCharity.Model.Responses;
using HeartForCharity.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.Services.VolunteerJobStateMachine
{
    public class BaseVolunteerJobState
    {
        protected readonly HeartForCharityDbContext _context;
        protected readonly ICurrentUserService _currentUserService;
        protected readonly IServiceProvider _serviceProvider;

        public BaseVolunteerJobState(
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService,
            IServiceProvider serviceProvider)
        {
            _context = context;
            _currentUserService = currentUserService;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<VolunteerJobResponse> CompleteAsync(int id)
            => throw new UserException("Action not allowed in current volunteer job status.");

        public virtual Task<VolunteerJobResponse> CancelAsync(int id)
            => throw new UserException("Action not allowed in current volunteer job status.");

        public BaseVolunteerJobState GetState(VolunteerJobStatus status) => status switch
        {
            VolunteerJobStatus.Active    => _serviceProvider.GetRequiredService<ActiveVolunteerJobState>(),
            VolunteerJobStatus.Completed => _serviceProvider.GetRequiredService<CompletedVolunteerJobState>(),
            VolunteerJobStatus.Cancelled => _serviceProvider.GetRequiredService<CancelledVolunteerJobState>(),
            _ => throw new UserException($"Unknown volunteer job status: {status}")
        };

        protected static VolunteerJobResponse MapToResponse(VolunteerJob entity) => new()
        {
            VolunteerJobId        = entity.VolunteerJobId,
            OrganisationProfileId = entity.OrganisationProfileId,
            OrganisationName      = entity.OrganisationProfile?.Name ?? string.Empty,
            CategoryId            = entity.CategoryId,
            CategoryName          = entity.Category?.Name,
            Title                 = entity.Title,
            Description           = entity.Description,
            RequiredSkills        = entity.VolunteerJobSkills
                                        .Select(vjs => new SkillResponse { SkillId = vjs.SkillId, Name = vjs.Skill?.Name ?? string.Empty, Description = vjs.Skill?.Description })
                                        .ToList(),
            StartDate             = entity.StartDate,
            EndDate               = entity.EndDate,
            IsRemote              = entity.IsRemote,
            PositionsAvailable    = entity.PositionsAvailable,
            PositionsFilled       = entity.PositionsFilled,
            Status                = entity.Status.ToString(),
            AddressId             = entity.AddressId,
            CityName              = entity.Address?.City?.Name,
            CreatedAt             = entity.CreatedAt
        };
    }
}
