namespace HeartForCharity.Model.Messages
{
    public class CampaignCancelledEvent
    {
        public int CampaignId { get; set; }
        public string CampaignTitle { get; set; } = null!;
    }
}
