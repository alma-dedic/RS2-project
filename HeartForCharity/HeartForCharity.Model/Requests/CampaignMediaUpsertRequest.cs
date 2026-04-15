namespace HeartForCharity.Model.Requests
{
    public class CampaignMediaUpsertRequest
    {
        public int CampaignId { get; set; }
        public string Url { get; set; } = null!;
        public string MediaType { get; set; } = "Image";
        public bool IsCover { get; set; } = false;
    }
}
