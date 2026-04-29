using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class SkillUpsertRequestValidator : AbstractValidator<SkillUpsertRequest>
    {
        public SkillUpsertRequestValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Skill name is required.")
                .MinimumLength(2).WithMessage("Skill name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("Skill name must not exceed 100 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(500).WithMessage("Description must not exceed 500 characters.")
                .When(x => x.Description != null);
        }
    }
}
