namespace HeartForCharity.Model.Requests
{
    public class ReviewInsertRequest
    {
        public int VolunteerApplicationId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
