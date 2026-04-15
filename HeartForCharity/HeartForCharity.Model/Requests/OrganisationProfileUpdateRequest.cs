namespace HeartForCharity.Model.Requests
{
    public class OrganisationProfileUpdateRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string? ContactEmail { get; set; }
        public string? ContactPhone { get; set; }
        public int? AddressId { get; set; }
        public string? LogoUrl { get; set; }
        public int? OrganisationTypeId { get; set; }
    }
}
