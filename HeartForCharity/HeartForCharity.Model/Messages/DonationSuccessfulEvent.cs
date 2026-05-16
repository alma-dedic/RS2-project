namespace HeartForCharity.Model.Messages
{
    public class DonationSuccessfulEvent
    {
        public int DonationId { get; set; }
        public int UserProfileId { get; set; }
        public string CampaignTitle { get; set; } = null!;
        public decimal Amount { get; set; }
    }
}
