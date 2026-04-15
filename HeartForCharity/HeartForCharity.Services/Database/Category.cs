using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class Category
    {
        [Key]
        public int CategoryId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = null!;

        [MaxLength(500)]
        public string? Description { get; set; }

        public CategoryAppliesTo AppliesTo { get; set; } = CategoryAppliesTo.Both;

        public virtual ICollection<Campaign> Campaigns { get; set; } = new List<Campaign>();
        public virtual ICollection<VolunteerJob> VolunteerJobs { get; set; } = new List<VolunteerJob>();
    }
    
}