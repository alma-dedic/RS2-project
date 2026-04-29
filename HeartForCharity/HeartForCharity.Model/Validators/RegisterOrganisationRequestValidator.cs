using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class RegisterOrganisationRequestValidator : AbstractValidator<RegisterOrganisationRequest>
    {
        public RegisterOrganisationRequestValidator()
        {
            // Account fields
            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Username is required.")
                .MaximumLength(100).WithMessage("Username must not exceed 100 characters.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Email is not valid.")
                .MaximumLength(255).WithMessage("Email must not exceed 255 characters.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters.")
                .MaximumLength(255).WithMessage("Password must not exceed 255 characters.")
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                .Matches("[0-9]").WithMessage("Password must contain at least one number.")
                .Matches("[!@#$%^&*()_+\\-={}|<>?]").WithMessage("Password must contain at least one special character.");

            // Organisation profile fields
            RuleFor(x => x.OrganisationName)
                .NotEmpty().WithMessage("Organisation name is required.")
                .MaximumLength(200).WithMessage("Organisation name must not exceed 200 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(2000).WithMessage("Description must not exceed 2000 characters.")
                .When(x => x.Description != null);

            RuleFor(x => x.ContactEmail)
                .EmailAddress().WithMessage("Contact email is not valid.")
                .MaximumLength(255).WithMessage("Contact email must not exceed 255 characters.")
                .When(x => !string.IsNullOrWhiteSpace(x.ContactEmail));

            RuleFor(x => x.ContactPhone)
                .Matches(@"^[+\d\s\-()]{6,20}$")
                .WithMessage("Enter a valid contact phone (6-20 characters, e.g. +387 33 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.ContactPhone));
        }
    }
}
