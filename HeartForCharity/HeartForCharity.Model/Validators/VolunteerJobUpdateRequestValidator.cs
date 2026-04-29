using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class VolunteerJobUpdateRequestValidator : AbstractValidator<VolunteerJobUpdateRequest>
    {
        public VolunteerJobUpdateRequestValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title is required.")
                .MaximumLength(200).WithMessage("Title must not exceed 200 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(4000).WithMessage("Description must not exceed 4000 characters.")
                .When(x => x.Description != null);

            RuleFor(x => x.PositionsAvailable)
                .GreaterThan(0).WithMessage("Positions available must be at least 1.");

            RuleFor(x => x.EndDate)
                .GreaterThan(x => x.StartDate).WithMessage("End date must be after start date.")
                .When(x => x.StartDate.HasValue && x.EndDate.HasValue);
        }
    }
}
