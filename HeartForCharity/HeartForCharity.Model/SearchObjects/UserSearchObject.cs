using System;
using System.Collections.Generic;
using System.Text;

namespace HeartForCharity.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? UserType { get; set; }
        public bool? IsActive { get; set; }
    }
}
