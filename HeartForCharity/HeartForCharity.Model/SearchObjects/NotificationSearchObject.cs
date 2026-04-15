using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Model.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public int? UserProfileId { get; set; }
        public bool? IsRead { get; set; }
        public string? Type { get; set; }
    }
}
