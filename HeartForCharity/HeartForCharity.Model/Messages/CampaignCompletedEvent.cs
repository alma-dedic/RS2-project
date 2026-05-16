namespace HeartForCharity.Model.Messages
{
    public class CampaignCompletedEvent
    {
        public int CampaignId { get; set; }
        public string CampaignTitle { get; set; } = null!;
    }
}
