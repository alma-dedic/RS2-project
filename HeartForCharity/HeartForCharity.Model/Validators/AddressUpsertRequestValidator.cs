using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class AddressUpsertRequestValidator : AbstractValidator<AddressUpsertRequest>
    {
        public AddressUpsertRequestValidator()
        {
            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("A valid city is required.");

            RuleFor(x => x.StreetName)
                .MaximumLength(200).WithMessage("Street name must not exceed 200 characters.")
                .When(x => x.StreetName != null);

            RuleFor(x => x.Number)
                .MaximumLength(20).WithMessage("Street number must not exceed 20 characters.")
                .When(x => x.Number != null);

            RuleFor(x => x.PostalCode)
                .MaximumLength(20).WithMessage("Postal code must not exceed 20 characters.")
                .When(x => x.PostalCode != null);
        }
    }
}
