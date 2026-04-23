using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "User")]
    public class NotificationController : BaseController<NotificationResponse, NotificationSearchObject>
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService service) : base(service)
        {
            _notificationService = service;
        }

        [HttpPatch("{id}/read")]
        public async Task<bool> MarkAsRead(int id)
        {
            return await _notificationService.MarkAsReadAsync(id);
        }

        [HttpPatch("read-all")]
        public async Task<bool> MarkAllAsRead()
        {
            return await _notificationService.MarkAllAsReadAsync();
        }
    }
}
