namespace HeartForCharity.Model.Messages
{
    public class VolunteerJobCompletedEvent
    {
        public int VolunteerJobId { get; set; }
        public string JobTitle { get; set; } = null!;
    }
}
