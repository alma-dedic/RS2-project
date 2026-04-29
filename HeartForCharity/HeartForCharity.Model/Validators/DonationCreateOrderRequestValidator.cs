using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class DonationCreateOrderRequestValidator : AbstractValidator<DonationCreateOrderRequest>
    {
        public const decimal MinAmount = 1.00m;
        public const decimal MaxAmount = 10_000.00m;

        public DonationCreateOrderRequestValidator()
        {
            RuleFor(x => x.CampaignId)
                .GreaterThan(0).WithMessage("Campaign is required.");

            RuleFor(x => x.Amount)
                .GreaterThanOrEqualTo(MinAmount)
                    .WithMessage($"Minimum donation amount is ${MinAmount:F2}.")
                .LessThanOrEqualTo(MaxAmount)
                    .WithMessage($"Maximum donation amount is ${MaxAmount:F2}.");
        }
    }
}
