using FluentValidation;
using HeartForCharity.Model.Requests;

namespace HeartForCharity.Model.Validators
{
    public class OrganisationProfileInsertRequestValidator : AbstractValidator<OrganisationProfileInsertRequest>
    {
        public OrganisationProfileInsertRequestValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Organisation name is required.")
                .MaximumLength(200).WithMessage("Name must not exceed 200 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(2000).WithMessage("Description must not exceed 2000 characters.")
                .When(x => x.Description != null);

            RuleFor(x => x.ContactEmail)
                .EmailAddress().WithMessage("Contact email is not valid.")
                .MaximumLength(255).WithMessage("Contact email must not exceed 255 characters.")
                .When(x => !string.IsNullOrWhiteSpace(x.ContactEmail));

            RuleFor(x => x.ContactPhone)
                .MaximumLength(20).WithMessage("Contact phone must not exceed 20 characters.")
                .When(x => x.ContactPhone != null);
        }
    }
}
