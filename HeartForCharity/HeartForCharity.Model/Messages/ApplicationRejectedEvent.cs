namespace HeartForCharity.Model.Messages
{
    public class ApplicationRejectedEvent
    {
        public int VolunteerApplicationId { get; set; }
        public int UserProfileId { get; set; }
        public string JobTitle { get; set; } = null!;
        public string ApplicantName { get; set; } = null!;
        public string? RejectionReason { get; set; }
    }
}
