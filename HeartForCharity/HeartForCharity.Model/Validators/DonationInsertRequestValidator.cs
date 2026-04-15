using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class DonationInsertRequestValidator : AbstractValidator<DonationInsertRequest>
    {
        public DonationInsertRequestValidator()
        {
            RuleFor(x => x.CampaignId)
                .GreaterThan(0).WithMessage("Campaign is required.");

            RuleFor(x => x.Amount)
                .GreaterThan(0).WithMessage("Donation amount must be greater than 0.");
        }
    }
}
