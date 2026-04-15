using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class ReviewInsertRequestValidator : AbstractValidator<ReviewInsertRequest>
    {
        public ReviewInsertRequestValidator()
        {
            RuleFor(x => x.VolunteerApplicationId)
                .GreaterThan(0).WithMessage("Volunteer application is required.");

            RuleFor(x => x.Rating)
                .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.");

            RuleFor(x => x.Comment)
                .MaximumLength(2000).WithMessage("Comment must not exceed 2000 characters.")
                .When(x => x.Comment != null);
        }
    }
}
