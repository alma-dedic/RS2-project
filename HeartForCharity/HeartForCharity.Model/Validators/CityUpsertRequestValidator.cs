using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class CityUpsertRequestValidator : AbstractValidator<CityUpsertRequest>
    {
        public CityUpsertRequestValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("City name is required.")
                .MinimumLength(2).WithMessage("City name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("City name must not exceed 100 characters.");

            RuleFor(x => x.CountryId)
                .GreaterThan(0).WithMessage("A valid country is required.");
        }
    }
}
