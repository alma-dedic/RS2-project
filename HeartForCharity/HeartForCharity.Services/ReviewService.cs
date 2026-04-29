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
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Review, ReviewInsertRequest, ReviewInsertRequest>, IReviewService
    {
        private readonly ICurrentUserService _currentUserService;

        public ReviewService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _currentUserService = currentUserService;
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            query = query.Include(r => r.OrganisationProfile)
                         .Include(r => r.UserProfile)
                         .Include(r => r.VolunteerApplication);

            if (search.OrganisationProfileId.HasValue)
                query = query.Where(r => r.OrganisationProfileId == search.OrganisationProfileId);
            if (search.UserProfileId.HasValue)
                query = query.Where(r => r.UserProfileId == search.UserProfileId);
            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating);
            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating);

            query = query.OrderByDescending(r => r.CreatedAt);

            return query;
        }

        protected override ReviewResponse MapToResponse(Review entity)
        {
            return new ReviewResponse
            {
                ReviewId = entity.ReviewId,
                VolunteerApplicationId = entity.VolunteerApplicationId,
                OrganisationProfileId = entity.OrganisationProfileId,
                OrganisationName = entity.OrganisationProfile?.Name ?? string.Empty,
                UserProfileId = entity.UserProfileId,
                ReviewerName = entity.UserProfile != null
                    ? $"{entity.UserProfile.FirstName} {entity.UserProfile.LastName}"
                    : string.Empty,
                ReviewerAvatarUrl = entity.UserProfile?.ProfilePictureUrl,
                Rating = entity.Rating,
                Comment = entity.Comment,
                CreatedAt = entity.CreatedAt
            };
        }

        protected override async Task BeforeInsert(Review entity, ReviewInsertRequest request)
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found for current user.");

            var application = await _context.VolunteerApplications
                .Include(va => va.VolunteerJob)
                .FirstOrDefaultAsync(va => va.VolunteerApplicationId == request.VolunteerApplicationId);

            if (application == null)
                throw new UserException("Volunteer application not found.");

            if (application.UserProfileId != userProfile.UserProfileId)
                throw new ForbiddenException("You can only review your own volunteer applications.");

            if (!application.IsCompleted)
                throw new UserException("You can only leave a review for completed activities.");

            var existingReview = await _context.Reviews
                .AnyAsync(r => r.VolunteerApplicationId == request.VolunteerApplicationId);

            if (existingReview)
                throw new UserException("A review for this application already exists.");

            entity.UserProfileId = userProfile.UserProfileId;
            entity.OrganisationProfileId = application.VolunteerJob.OrganisationProfileId;
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeDelete(Review entity)
        {
            var userProfile = await _context.UserProfiles.FindAsync(entity.UserProfileId);

            if (userProfile == null || userProfile.UserId != _currentUserService.UserId)
                throw new ForbiddenException("You can only delete your own reviews.");
        }
    }
}
