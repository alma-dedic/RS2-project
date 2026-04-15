using HeartForCharity.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HeartForCharity.Services.Database
{
    public class User
    {
        [Key]
        public int UserId { get; set; }

        [Required, MaxLength(100)]
        public string Username { get; set; } = null!;

        [Required, MaxLength(255), EmailAddress]
        public string Email { get; set; } = null!;

        [Required, MaxLength(255)]
        public string PasswordHash { get; set; } = null!;

        [Required, MaxLength(255)]
        public string PasswordSalt { get; set; } = null!;

        [Required]
        public UserType UserType { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DeletedAt { get; set; }

        public virtual UserProfile? UserProfile { get; set; }
        public virtual OrganisationProfile? OrganisationProfile { get; set; }
    }
}