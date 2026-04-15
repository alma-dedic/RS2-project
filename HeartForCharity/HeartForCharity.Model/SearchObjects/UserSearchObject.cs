using System;
using System.Collections.Generic;
using System.Text;

namespace HeartForCharity.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        /// <summary>FTS matches Username and Email</summary>
        public string? UserType { get; set; }
        public bool? IsActive { get; set; }
    }
}
