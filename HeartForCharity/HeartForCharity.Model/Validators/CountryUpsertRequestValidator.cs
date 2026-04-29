using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class CountryUpsertRequestValidator : AbstractValidator<CountryUpsertRequest>
    {
        public CountryUpsertRequestValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Country name is required.")
                .MinimumLength(2).WithMessage("Country name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("Country name must not exceed 100 characters.");

            RuleFor(x => x.ISOCode)
                .MaximumLength(10).WithMessage("ISO code must not exceed 10 characters.")
                .When(x => x.ISOCode != null);
        }
    }
}
