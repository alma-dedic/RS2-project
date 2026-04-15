using FluentValidation;
using HeartForCharity.Model.Requests;
using System.Linq;

namespace HeartForCharity.Model.Validators
{
    public class CampaignMediaUpsertRequestValidator : AbstractValidator<CampaignMediaUpsertRequest>
    {
        private static readonly string[] AllowedMediaTypes = { "Image", "Video", "Document" };

        public CampaignMediaUpsertRequestValidator()
        {
            RuleFor(x => x.CampaignId)
                .GreaterThan(0).WithMessage("Campaign is required.");

            RuleFor(x => x.Url)
                .NotEmpty().WithMessage("URL is required.")
                .MaximumLength(500).WithMessage("URL must not exceed 500 characters.");

            RuleFor(x => x.MediaType)
                .Must(t => AllowedMediaTypes.Contains(t)).WithMessage("Media type must be Image, Video, or Document.");
        }
    }
}
