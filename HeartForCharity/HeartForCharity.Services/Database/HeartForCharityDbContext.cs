using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace HeartForCharity.Services.Database
{
    public class HeartForCharityDbContext : DbContext
    {
        public HeartForCharityDbContext(DbContextOptions<HeartForCharityDbContext> options) : base(options)
        {
        }

        // DbSets
        // Korisnici i profili
        public DbSet<User> Users { get; set; }
        public DbSet<UserProfile> UserProfiles { get; set; }
        public DbSet<OrganisationProfile> OrganisationProfiles { get; set; }
        public DbSet<OrganisationType> OrganisationTypes { get; set; }

        // Kampanje i donacije
        public DbSet<Campaign> Campaigns { get; set; }
        public DbSet<CampaignMedia> CampaignMedias { get; set; }
        public DbSet<Donation> Donations { get; set; }

        // Volontiranje
        public DbSet<VolunteerJob> VolunteerJobs { get; set; }
        public DbSet<VolunteerApplication> VolunteerApplications { get; set; }
        public DbSet<VolunteerSkill> VolunteerSkills { get; set; }
        public DbSet<VolunteerJobSkill> VolunteerJobSkills { get; set; }
        public DbSet<Skill> Skills { get; set; }

        // Recenzije, notifikacije, preporuke
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Recommendation> Recommendations { get; set; }

        // Autentifikacija
        public DbSet<RefreshToken> RefreshTokens { get; set; }

        // Šifarnici
        public DbSet<Category> Categories { get; set; }
        public DbSet<Address> Addresses { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Country> Countries { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ========== JEDINSTVENI INDEKSI ==========
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            // Jedan korisnik ne može se prijaviti dva puta na isti posao
            modelBuilder.Entity<VolunteerApplication>()
                .HasIndex(va => new { va.VolunteerJobId, va.UserProfileId })
                .IsUnique();

            // Isti korisnik ne može imati duplu vještinu
            modelBuilder.Entity<VolunteerSkill>()
                .HasIndex(vs => new { vs.UserProfileId, vs.SkillId })
                .IsUnique();

            // Isti skill ne može biti dodan dva puta na isti posao
            modelBuilder.Entity<VolunteerJobSkill>()
                .HasIndex(vjs => new { vjs.VolunteerJobId, vjs.SkillId })
                .IsUnique();

            // ========== OBIČNI INDEKSI ZA ČESTA PRETRAŽIVANJA ==========
            modelBuilder.Entity<Campaign>()
                .HasIndex(c => c.Status);

            modelBuilder.Entity<Campaign>()
                .HasIndex(c => c.CategoryId);

            modelBuilder.Entity<VolunteerJob>()
                .HasIndex(vj => vj.Status);

            modelBuilder.Entity<VolunteerApplication>()
                .HasIndex(va => va.Status);

            modelBuilder.Entity<Donation>()
                .HasIndex(d => d.CampaignId);

            modelBuilder.Entity<Notification>()
                .HasIndex(n => n.UserProfileId);

            // ========== PRECIZNOST DECIMALNIH POLJA ==========
            modelBuilder.Entity<Campaign>()
                .Property(c => c.TargetAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Campaign>()
                .Property(c => c.CurrentAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Donation>()
                .Property(d => d.Amount)
                .HasPrecision(18, 2);

            // ========== RELACIJE ==========

            // User -> UserProfile (1:1)
            // Cascade: ako obrišeš User, briše se i UserProfile
            modelBuilder.Entity<UserProfile>()
                .HasOne(up => up.User)
                .WithOne(u => u.UserProfile)
                .HasForeignKey<UserProfile>(up => up.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // User -> OrganisationProfile (1:1)
            // Cascade: ako obrišeš User, briše se i OrganisationProfile
            modelBuilder.Entity<OrganisationProfile>()
                .HasOne(op => op.User)
                .WithOne(u => u.OrganisationProfile)
                .HasForeignKey<OrganisationProfile>(op => op.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // OrganisationProfile -> Campaign (1:N)
            // Restrict: ne dozvoliti brisanje organizacije dok ima kampanja
            modelBuilder.Entity<Campaign>()
                .HasOne(c => c.OrganisationProfile)
                .WithMany(op => op.Campaigns)
                .HasForeignKey(c => c.OrganisationProfileId)
                .OnDelete(DeleteBehavior.Restrict);

            // OrganisationProfile -> VolunteerJob (1:N)
            // Restrict: ne dozvoliti brisanje organizacije dok ima poslova
            modelBuilder.Entity<VolunteerJob>()
                .HasOne(vj => vj.OrganisationProfile)
                .WithMany(op => op.VolunteerJobs)
                .HasForeignKey(vj => vj.OrganisationProfileId)
                .OnDelete(DeleteBehavior.Restrict);

            // Campaign -> CampaignMedia (1:N)
            // Cascade: mediji nemaju smisla bez kampanje
            modelBuilder.Entity<CampaignMedia>()
                .HasOne(cm => cm.Campaign)
                .WithMany(c => c.CampaignMedias)
                .HasForeignKey(cm => cm.CampaignId)
                .OnDelete(DeleteBehavior.Cascade);

            // Campaign -> Donation (1:N)
            // Restrict: čuvati donacije čak i ako se kampanja obriše (finansijska historija)
            modelBuilder.Entity<Donation>()
                .HasOne(d => d.Campaign)
                .WithMany(c => c.Donations)
                .HasForeignKey(d => d.CampaignId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserProfile -> Donation (1:N)
            // NoAction: anonimne donacije nemaju UserProfile, nullable FK
            modelBuilder.Entity<Donation>()
                .HasOne(d => d.UserProfile)
                .WithMany(up => up.Donations)
                .HasForeignKey(d => d.UserProfileId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.NoAction);

            // VolunteerJob -> VolunteerApplication (1:N)
            // Restrict: čuvati prijave čak i ako se posao obriše
            modelBuilder.Entity<VolunteerApplication>()
                .HasOne(va => va.VolunteerJob)
                .WithMany(vj => vj.VolunteerApplications)
                .HasForeignKey(va => va.VolunteerJobId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserProfile -> VolunteerApplication (1:N)
            // Restrict: sprječava višestruke cascade putanje prema Review
            modelBuilder.Entity<VolunteerApplication>()
                .HasOne(va => va.UserProfile)
                .WithMany(up => up.VolunteerApplications)
                .HasForeignKey(va => va.UserProfileId)
                .OnDelete(DeleteBehavior.Restrict);

            // VolunteerApplication -> Review (1:0..1)
            // Restrict: jedna prijava = jedna recenzija max, ne brisati kaskadno
            modelBuilder.Entity<Review>()
                .HasOne(r => r.VolunteerApplication)
                .WithOne(va => va.Review)
                .HasForeignKey<Review>(r => r.VolunteerApplicationId)
                .OnDelete(DeleteBehavior.Restrict);

            // OrganisationProfile -> Review (1:N)
            // Restrict: čuvati recenzije čak i ako se organizacija obriše
            modelBuilder.Entity<Review>()
                .HasOne(r => r.OrganisationProfile)
                .WithMany(op => op.Reviews)
                .HasForeignKey(r => r.OrganisationProfileId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserProfile -> Review (1:N)
            // NoAction: sprječava cycle — UserProfile već ima putanju kroz VolunteerApplication
            modelBuilder.Entity<Review>()
                .HasOne(r => r.UserProfile)
                .WithMany(up => up.Reviews)
                .HasForeignKey(r => r.UserProfileId)
                .OnDelete(DeleteBehavior.NoAction);

            // UserProfile -> Notification (1:N)
            // Cascade: notifikacije nemaju smisla bez korisnika
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.UserProfile)
                .WithMany(up => up.Notifications)
                .HasForeignKey(n => n.UserProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            // VolunteerApplication -> Notification (1:N)
            // NoAction: notifikacija ostaje kao historija čak i ako se prijava obriše
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.VolunteerApplication)
                .WithMany(va => va.Notifications)
                .HasForeignKey(n => n.VolunteerApplicationId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.NoAction);

            // Many-to-Many: UserProfile <-> Skill (preko VolunteerSkill)
            modelBuilder.Entity<VolunteerSkill>()
                .HasOne(vs => vs.UserProfile)
                .WithMany(up => up.VolunteerSkills)
                .HasForeignKey(vs => vs.UserProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<VolunteerSkill>()
                .HasOne(vs => vs.Skill)
                .WithMany(s => s.VolunteerSkills)
                .HasForeignKey(vs => vs.SkillId)
                .OnDelete(DeleteBehavior.Restrict);

            // Many-to-Many: VolunteerJob <-> Skill (preko VolunteerJobSkill)
            modelBuilder.Entity<VolunteerJobSkill>()
                .HasOne(vjs => vjs.VolunteerJob)
                .WithMany(vj => vj.VolunteerJobSkills)
                .HasForeignKey(vjs => vjs.VolunteerJobId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<VolunteerJobSkill>()
                .HasOne(vjs => vjs.Skill)
                .WithMany()
                .HasForeignKey(vjs => vjs.SkillId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserProfile -> Recommendation (1:N)
            // Cascade: preporuke nemaju smisla bez korisnika
            modelBuilder.Entity<Recommendation>()
                .HasOne(r => r.UserProfile)
                .WithMany(up => up.Recommendations)
                .HasForeignKey(r => r.UserProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            // Address -> City (N:1)
            modelBuilder.Entity<Address>()
                .HasOne(a => a.City)
                .WithMany(c => c.Addresses)
                .HasForeignKey(a => a.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            // City -> Country (N:1)
            modelBuilder.Entity<City>()
                .HasOne(c => c.Country)
                .WithMany(c => c.Cities)
                .HasForeignKey(c => c.CountryId)
                .OnDelete(DeleteBehavior.Restrict);
        }

    }
}
