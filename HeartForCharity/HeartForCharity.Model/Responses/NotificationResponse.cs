using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.Responses
{
    public class NotificationResponse
    {
        public int NotificationId { get; set; }
        public int UserProfileId { get; set; }
        public int? VolunteerApplicationId { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public string Type { get; set; } = null!;
        public bool IsRead { get; set; }
        public DateTime SentDateTime { get; set; }
    }
}
