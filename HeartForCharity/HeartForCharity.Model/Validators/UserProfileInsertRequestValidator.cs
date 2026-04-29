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
                .MinimumLength(2).WithMessage("First name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required.")
                .MinimumLength(2).WithMessage("Last name must be at least 2 characters.")
                .MaximumLength(100).WithMessage("Last name must not exceed 100 characters.");

            RuleFor(x => x.PhoneNumber)
                .Matches(@"^[+\d\s\-()]{6,20}$")
                .WithMessage("Enter a valid phone number (6-20 characters, e.g. +387 61 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.DateOfBirth)
                .LessThan(DateTime.UtcNow).WithMessage("Date of birth must be in the past.")
                .When(x => x.DateOfBirth.HasValue);
        }
    }
}
