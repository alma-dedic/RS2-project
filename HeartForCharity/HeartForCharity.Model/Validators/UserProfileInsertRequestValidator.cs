using FluentValidation;
using HeartForCharity.Model.Requests;
using System;

namespace HeartForCharity.Model.Validators
{
    public class UserProfileInsertRequestValidator : AbstractValidator<UserProfileInsertRequest>
    {
        public UserProfileInsertRequestValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required.")
                .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required.")
                .MaximumLength(100).WithMessage("Last name must not exceed 100 characters.");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Phone number must not exceed 20 characters.")
                .When(x => x.PhoneNumber != null);

            RuleFor(x => x.DateOfBirth)
                .LessThan(DateTime.UtcNow).WithMessage("Date of birth must be in the past.")
                .When(x => x.DateOfBirth.HasValue);
        }
    }
}
