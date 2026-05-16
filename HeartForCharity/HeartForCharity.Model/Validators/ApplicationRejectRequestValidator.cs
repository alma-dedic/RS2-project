using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class ApplicationRejectRequestValidator : AbstractValidator<ApplicationRejectRequest>
    {
        public ApplicationRejectRequestValidator()
        {
            RuleFor(x => x.RejectionReason)
                .NotEmpty().WithMessage("Rejection reason is required.")
                .MaximumLength(500).WithMessage("Rejection reason must not exceed 500 characters.");
        }
    }
}
