namespace HeartForCharity.Model.Requests
{
    public class VolunteerApplicationInsertRequest
    {
        public int VolunteerJobId { get; set; }
        public string? CoverLetter { get; set; }
        public string? ResumeUrl { get; set; }
    }
}
