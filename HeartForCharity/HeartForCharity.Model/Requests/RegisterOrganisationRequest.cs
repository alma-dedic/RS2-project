namespace HeartForCharity.Model.Requests
{
    public class RegisterOrganisationRequest
    {
        // Account fields
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Password { get; set; } = null!;

        // Organisation profile fields
        public string OrganisationName { get; set; } = null!;
        public string? Description { get; set; }
        public string? ContactEmail { get; set; }
        public string? ContactPhone { get; set; }
    }
}
