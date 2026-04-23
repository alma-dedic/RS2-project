using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Exceptions;
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
    public class NotificationService : BaseService<NotificationResponse, NotificationSearchObject, Notification>, INotificationService
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ICurrentUserService _currentUserService;

        public NotificationService(HeartForCharityDbContext context, IMapper mapper, ICurrentUserService currentUserService)
            : base(context, mapper)
        {
            _context = context;
            _currentUserService = currentUserService;
        }

        protected override IQueryable<Notification> ApplyFilter(IQueryable<Notification> query, NotificationSearchObject search)
        {
            query = query.Include(n => n.UserProfile);

            var userId = _currentUserService.UserId;
            query = query.Where(n => n.UserProfile.UserId == userId);

            if (search.IsRead.HasValue)
                query = query.Where(n => n.IsRead == search.IsRead);
            if (!string.IsNullOrWhiteSpace(search.Type) && Enum.TryParse<NotificationType>(search.Type, out var type))
                query = query.Where(n => n.Type == type);

            return query.OrderByDescending(n => n.CreatedAt);
        }

        protected override NotificationResponse MapToResponse(Notification entity)
        {
            return new NotificationResponse
            {
                NotificationId         = entity.NotificationId,
                UserProfileId          = entity.UserProfileId,
                VolunteerApplicationId = entity.VolunteerApplicationId,
                Title                  = entity.Title,
                Message                = entity.Message,
                Type                   = entity.Type.ToString(),
                IsRead                 = entity.IsRead,
                SentDateTime           = entity.SentDateTime
            };
        }

        public async Task<bool> MarkAsReadAsync(int notificationId)
        {
            var notification = await _context.Notifications.FindAsync(notificationId);

            if (notification == null)
                throw new UserException("Notification not found.");

            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null || notification.UserProfileId != userProfile.UserProfileId)
                throw new ForbiddenException("You can only mark your own notifications as read.");

            notification.IsRead = true;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkAllAsReadAsync()
        {
            var userProfile = await _context.UserProfiles
                .FirstOrDefaultAsync(up => up.UserId == _currentUserService.UserId);

            if (userProfile == null)
                throw new UserException("User profile not found.");

            var unread = await _context.Notifications
                .Where(n => n.UserProfileId == userProfile.UserProfileId && !n.IsRead)
                .ToListAsync();

            foreach (var n in unread)
                n.IsRead = true;

            await _context.SaveChangesAsync();
            return true;
        }
    }
}
