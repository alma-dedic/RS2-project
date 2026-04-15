namespace HeartForCharity.Model.Requests
{
    public class DonationCreateOrderRequest
    {
        public int CampaignId { get; set; }
        public decimal Amount { get; set; }
        public bool IsAnonymous { get; set; } = false;
    }
}
