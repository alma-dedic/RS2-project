using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class CategoryUpsertRequestValidator : AbstractValidator<CategoryUpsertRequest>
    {
        public CategoryUpsertRequestValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Category name is required.")
                .MinimumLength(2).WithMessage("Category name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("Category name must not exceed 100 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(500).WithMessage("Description must not exceed 500 characters.")
                .When(x => x.Description != null);

            RuleFor(x => x.AppliesTo)
                .IsInEnum().WithMessage("Invalid category type.");
        }
    }
}
