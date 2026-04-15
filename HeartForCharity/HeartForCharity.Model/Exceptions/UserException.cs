using System;

namespace HeartForCharity.Model.Exceptions
{
    public class UserException : Exception
    {
        public UserException(string message) : base(message) { }
    }
}
