using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class VolunteerApplicationInsertRequestValidator : AbstractValidator<VolunteerApplicationInsertRequest>
    {
        public VolunteerApplicationInsertRequestValidator()
        {
            RuleFor(x => x.VolunteerJobId)
                .GreaterThan(0).WithMessage("Volunteer job is required.");

            RuleFor(x => x.CoverLetter)
                .MaximumLength(4000).WithMessage("Cover letter must not exceed 4000 characters.")
                .When(x => x.CoverLetter != null);

            RuleFor(x => x.ResumeUrl)
                .MaximumLength(500).WithMessage("Resume URL must not exceed 500 characters.")
                .When(x => x.ResumeUrl != null);
        }
    }
}
