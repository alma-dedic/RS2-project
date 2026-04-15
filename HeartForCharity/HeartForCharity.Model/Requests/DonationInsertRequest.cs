namespace HeartForCharity.Model.Requests
{
    public class DonationInsertRequest
    {
        public int CampaignId { get; set; }
        public decimal Amount { get; set; }
        public bool IsAnonymous { get; set; } = false;
        public string? PayPalTransactionId { get; set; }
    }
}
