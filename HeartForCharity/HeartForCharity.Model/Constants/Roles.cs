using HeartForCharity.Model.Enums;

namespace HeartForCharity.Model.Constants
{
    public static class Roles
    {
        public const string Admin = nameof(UserType.Admin);
        public const string User = nameof(UserType.User);
        public const string Organisation = nameof(UserType.Organisation);

        public const string OrganisationOrAdmin = Organisation + "," + Admin;
        public const string All = User + "," + Organisation + "," + Admin;
    }
}
