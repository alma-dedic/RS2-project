using HeartForCharity.Model.Enums;

namespace HeartForCharity.Model.Requests
{
    public class CategoryUpsertRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public CategoryAppliesTo AppliesTo { get; set; } = CategoryAppliesTo.Both;
    }
}
