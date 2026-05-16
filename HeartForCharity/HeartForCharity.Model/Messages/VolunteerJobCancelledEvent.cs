namespace HeartForCharity.Model.Messages
{
    public class VolunteerJobCancelledEvent
    {
        public int VolunteerJobId { get; set; }
        public string JobTitle { get; set; } = null!;
    }
}
