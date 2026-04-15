using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class VolunteerSkillInsertRequestValidator : AbstractValidator<VolunteerSkillInsertRequest>
    {
        public VolunteerSkillInsertRequestValidator()
        {
            RuleFor(x => x.SkillId)
                .GreaterThan(0).WithMessage("Skill is required.");
        }
    }
}
