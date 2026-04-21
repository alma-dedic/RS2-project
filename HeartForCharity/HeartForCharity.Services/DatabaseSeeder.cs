using HeartForCharity.Model.Enums;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(HeartForCharityDbContext context)
        {
            if (await context.Users.AnyAsync())
                return;

            // ── 1. COUNTRIES ──────────────────────────────────────────────────────
            var bih = new Country { Name = "Bosnia and Herzegovina" };
            var usa = new Country { Name = "United States" };
            var uk = new Country { Name = "United Kingdom" };
            var germany = new Country { Name = "Germany" };
            var france = new Country { Name = "France" };
            await context.Countries.AddRangeAsync(bih, usa, uk, germany, france);
            await context.SaveChangesAsync();

            // ── 2. CITIES ─────────────────────────────────────────────────────────
            var sarajevo = new City { Name = "Sarajevo", CountryId = bih.CountryId };
            var mostar = new City { Name = "Mostar", CountryId = bih.CountryId };
            var banjaLuka = new City { Name = "Banja Luka", CountryId = bih.CountryId };
            var newYork = new City { Name = "New York", CountryId = usa.CountryId };
            var losAngeles = new City { Name = "Los Angeles", CountryId = usa.CountryId };
            var london = new City { Name = "London", CountryId = uk.CountryId };
            var manchester = new City { Name = "Manchester", CountryId = uk.CountryId };
            var berlin = new City { Name = "Berlin", CountryId = germany.CountryId };
            var paris = new City { Name = "Paris", CountryId = france.CountryId };
            await context.Cities.AddRangeAsync(sarajevo, mostar, banjaLuka, newYork, losAngeles, london, manchester, berlin, paris);
            await context.SaveChangesAsync();

            // ── 3. ORGANISATION TYPES ─────────────────────────────────────────────
            var ngoType = new OrganisationType { Name = "Humanitarian NGO" };
            var foundationType = new OrganisationType { Name = "Charitable Foundation" };
            await context.OrganisationTypes.AddRangeAsync(ngoType, foundationType);
            await context.SaveChangesAsync();

            // ── 4. CATEGORIES ─────────────────────────────────────────────────────
            var catChildren = new Category { Name = "Children", AppliesTo = CategoryAppliesTo.Both };
            var catHealth = new Category { Name = "Health", AppliesTo = CategoryAppliesTo.Both };
            var catDisaster = new Category { Name = "Disaster Relief", AppliesTo = CategoryAppliesTo.Campaign };
            var catEducation = new Category { Name = "Education", AppliesTo = CategoryAppliesTo.Both };
            var catFood = new Category { Name = "Food & Shelter", AppliesTo = CategoryAppliesTo.Both };
            await context.Categories.AddRangeAsync(catChildren, catHealth, catDisaster, catEducation, catFood);
            await context.SaveChangesAsync();

            // ── 5. SKILLS ─────────────────────────────────────────────────────────
            var skillFirstAid = new Skill { Name = "First Aid / Medical" };
            var skillTeaching = new Skill { Name = "Teaching / Tutoring" };
            var skillFoodDist = new Skill { Name = "Food Distribution" };
            var skillLogistics = new Skill { Name = "Logistics" };
            await context.Skills.AddRangeAsync(skillFirstAid, skillTeaching, skillFoodDist, skillLogistics);
            await context.SaveChangesAsync();

            // ── 6. ADDRESSES ──────────────────────────────────────────────────────
            var addrHope = new Address { CityId = london.CityId };
            var addrGlobal = new Address { CityId = newYork.CityId };
            var addrHelping = new Address { CityId = sarajevo.CityId };
            var addrBright = new Address { CityId = berlin.CityId };
            var addrCare = new Address { CityId = paris.CityId };
            var addrJohn = new Address { CityId = sarajevo.CityId };
            var addrJane = new Address { CityId = london.CityId };
            var addrMike = new Address { CityId = newYork.CityId };
            var addrEmily = new Address { CityId = manchester.CityId };
            var addrChris = new Address { CityId = berlin.CityId };
            var addrSarah = new Address { CityId = paris.CityId };
            var addrDavid = new Address { CityId = losAngeles.CityId };
            var addrLisa = new Address { CityId = mostar.CityId };
            var addrJames = new Address { CityId = banjaLuka.CityId };
            var addrEmma = new Address { CityId = newYork.CityId };
            await context.Addresses.AddRangeAsync(
                addrHope, addrGlobal, addrHelping, addrBright, addrCare,
                addrJohn, addrJane, addrMike, addrEmily, addrChris,
                addrSarah, addrDavid, addrLisa, addrJames, addrEmma);
            await context.SaveChangesAsync();

            // ── 7. USERS ──────────────────────────────────────────────────────────
            var admin = CreateUser("admin", "admin@heartforcharity.com", "Admin123!", UserType.Admin);
            var hopeUser = CreateUser("hope_org", "hope@foundation.com", "Test123!", UserType.Organisation);
            var globalUser = CreateUser("globalaid_org", "global@aidnetwork.com", "Test123!", UserType.Organisation);
            var helpingUser = CreateUser("helping_org", "helping@handscharity.com", "Test123!", UserType.Organisation);
            var brightUser = CreateUser("bright_org", "bright@futurengo.com", "Test123!", UserType.Organisation);
            var careUser = CreateUser("careshare_org", "care@shareassociation.com", "Test123!", UserType.Organisation);
            var johnUser = CreateUser("john_doe", "john@example.com", "Test123!", UserType.User);
            var janeUser = CreateUser("jane_smith", "jane@example.com", "Test123!", UserType.User);
            var mikeUser = CreateUser("mike_johnson", "mike@example.com", "Test123!", UserType.User);
            var emilyUser = CreateUser("emily_davis", "emily@example.com", "Test123!", UserType.User);
            var chrisUser = CreateUser("chris_wilson", "chris@example.com", "Test123!", UserType.User);
            var sarahUser = CreateUser("sarah_brown", "sarah@example.com", "Test123!", UserType.User);
            var davidUser = CreateUser("david_miller", "david@example.com", "Test123!", UserType.User);
            var lisaUser = CreateUser("lisa_taylor", "lisa@example.com", "Test123!", UserType.User);
            var jamesUser = CreateUser("james_anderson", "james@example.com", "Test123!", UserType.User);
            var emmaUser = CreateUser("emma_thomas", "emma@example.com", "Test123!", UserType.User);
            await context.Users.AddRangeAsync(
                admin, hopeUser, globalUser, helpingUser, brightUser, careUser,
                johnUser, janeUser, mikeUser, emilyUser, chrisUser, sarahUser,
                davidUser, lisaUser, jamesUser, emmaUser);
            await context.SaveChangesAsync();

            // ── 8. ORGANISATION PROFILES ──────────────────────────────────────────
            var now = DateTime.UtcNow;
            var hopeOrg = new OrganisationProfile
            {
                UserId = hopeUser.UserId, Name = "Hope Foundation",
                Description = "Dedicated to improving the lives of vulnerable children worldwide.",
                ContactEmail = "contact@hopefoundation.org", ContactPhone = "+44 20 1234 5678",
                OrganisationTypeId = foundationType.OrganisationTypeId,
                AddressId = addrHope.AddressId, IsVerified = true,
                CreatedAt = now, UpdatedAt = now
            };
            var globalOrg = new OrganisationProfile
            {
                UserId = globalUser.UserId, Name = "Global Aid Network",
                Description = "Providing emergency relief and long-term development aid globally.",
                ContactEmail = "info@globalaidnetwork.org", ContactPhone = "+1 212 555 0100",
                OrganisationTypeId = ngoType.OrganisationTypeId,
                AddressId = addrGlobal.AddressId, IsVerified = true,
                CreatedAt = now, UpdatedAt = now
            };
            var helpingOrg = new OrganisationProfile
            {
                UserId = helpingUser.UserId, Name = "Helping Hands Charity",
                Description = "Fighting hunger and homelessness in communities across the Balkans.",
                ContactEmail = "hello@helpinghands.org", ContactPhone = "+387 33 123 456",
                OrganisationTypeId = foundationType.OrganisationTypeId,
                AddressId = addrHelping.AddressId, IsVerified = true,
                CreatedAt = now, UpdatedAt = now
            };
            var brightOrg = new OrganisationProfile
            {
                UserId = brightUser.UserId, Name = "Bright Future NGO",
                Description = "Empowering youth through education and vocational training.",
                ContactEmail = "contact@brightfuture.org", ContactPhone = "+49 30 987 6543",
                OrganisationTypeId = ngoType.OrganisationTypeId,
                AddressId = addrBright.AddressId, IsVerified = true,
                CreatedAt = now, UpdatedAt = now
            };
            var careOrg = new OrganisationProfile
            {
                UserId = careUser.UserId, Name = "Care & Share Association",
                Description = "Building stronger communities through mutual aid and compassion. We run year-round programmes providing food, shelter, health screenings and community events across the city.",
                ContactEmail = "info@careshare.org", ContactPhone = "+33 1 4567 8901",
                OrganisationTypeId = ngoType.OrganisationTypeId,
                AddressId = addrCare.AddressId, IsVerified = true,
                CreatedAt = now, UpdatedAt = now
            };
            await context.OrganisationProfiles.AddRangeAsync(hopeOrg, globalOrg, helpingOrg, brightOrg, careOrg);
            await context.SaveChangesAsync();

            // ── 9. USER PROFILES ──────────────────────────────────────────────────
            var johnProfile = new UserProfile { UserId = johnUser.UserId, FirstName = "John", LastName = "Doe", PhoneNumber = "+387 61 111 111", DateOfBirth = new DateTime(1995, 3, 15), AddressId = addrJohn.AddressId, CreatedAt = now, UpdatedAt = now };
            var janeProfile = new UserProfile { UserId = janeUser.UserId, FirstName = "Jane", LastName = "Smith", PhoneNumber = "+44 7700 900001", DateOfBirth = new DateTime(1992, 7, 22), AddressId = addrJane.AddressId, CreatedAt = now, UpdatedAt = now };
            var mikeProfile = new UserProfile { UserId = mikeUser.UserId, FirstName = "Mike", LastName = "Johnson", PhoneNumber = "+1 212 555 0101", DateOfBirth = new DateTime(1990, 11, 8), AddressId = addrMike.AddressId, CreatedAt = now, UpdatedAt = now };
            var emilyProfile = new UserProfile { UserId = emilyUser.UserId, FirstName = "Emily", LastName = "Davis", PhoneNumber = "+44 7700 900002", DateOfBirth = new DateTime(1998, 1, 30), AddressId = addrEmily.AddressId, CreatedAt = now, UpdatedAt = now };
            var chrisProfile = new UserProfile { UserId = chrisUser.UserId, FirstName = "Chris", LastName = "Wilson", PhoneNumber = "+49 151 12345678", DateOfBirth = new DateTime(1993, 5, 14), AddressId = addrChris.AddressId, CreatedAt = now, UpdatedAt = now };
            var sarahProfile = new UserProfile { UserId = sarahUser.UserId, FirstName = "Sarah", LastName = "Brown", PhoneNumber = "+33 6 12 34 56 78", DateOfBirth = new DateTime(1996, 9, 20), AddressId = addrSarah.AddressId, CreatedAt = now, UpdatedAt = now };
            var davidProfile = new UserProfile { UserId = davidUser.UserId, FirstName = "David", LastName = "Miller", PhoneNumber = "+1 310 555 0199", DateOfBirth = new DateTime(1988, 4, 3), AddressId = addrDavid.AddressId, CreatedAt = now, UpdatedAt = now };
            var lisaProfile = new UserProfile { UserId = lisaUser.UserId, FirstName = "Lisa", LastName = "Taylor", PhoneNumber = "+387 36 222 333", DateOfBirth = new DateTime(1997, 12, 11), AddressId = addrLisa.AddressId, CreatedAt = now, UpdatedAt = now };
            var jamesProfile = new UserProfile { UserId = jamesUser.UserId, FirstName = "James", LastName = "Anderson", PhoneNumber = "+387 51 333 444", DateOfBirth = new DateTime(1991, 6, 25), AddressId = addrJames.AddressId, CreatedAt = now, UpdatedAt = now };
            var emmaProfile = new UserProfile { UserId = emmaUser.UserId, FirstName = "Emma", LastName = "Thomas", PhoneNumber = "+1 212 555 0202", DateOfBirth = new DateTime(1994, 8, 17), AddressId = addrEmma.AddressId, CreatedAt = now, UpdatedAt = now };
            await context.UserProfiles.AddRangeAsync(johnProfile, janeProfile, mikeProfile, emilyProfile, chrisProfile, sarahProfile, davidProfile, lisaProfile, jamesProfile, emmaProfile);
            await context.SaveChangesAsync();

            // ── 10. VOLUNTEER SKILLS ──────────────────────────────────────────────
            await context.VolunteerSkills.AddRangeAsync(
                new VolunteerSkill { UserProfileId = johnProfile.UserProfileId, SkillId = skillFirstAid.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = johnProfile.UserProfileId, SkillId = skillTeaching.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = janeProfile.UserProfileId, SkillId = skillFirstAid.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = janeProfile.UserProfileId, SkillId = skillFoodDist.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = mikeProfile.UserProfileId, SkillId = skillFoodDist.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = mikeProfile.UserProfileId, SkillId = skillLogistics.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = emilyProfile.UserProfileId, SkillId = skillTeaching.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = emilyProfile.UserProfileId, SkillId = skillLogistics.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = chrisProfile.UserProfileId, SkillId = skillFirstAid.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = sarahProfile.UserProfileId, SkillId = skillFoodDist.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = davidProfile.UserProfileId, SkillId = skillLogistics.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = lisaProfile.UserProfileId, SkillId = skillTeaching.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = jamesProfile.UserProfileId, SkillId = skillFirstAid.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = jamesProfile.UserProfileId, SkillId = skillLogistics.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = emmaProfile.UserProfileId, SkillId = skillTeaching.SkillId, CreatedAt = now },
                new VolunteerSkill { UserProfileId = emmaProfile.UserProfileId, SkillId = skillFoodDist.SkillId, CreatedAt = now }
            );
            await context.SaveChangesAsync();

            // ── 11. CAMPAIGNS ─────────────────────────────────────────────────────
            var camp1 = new Campaign { OrganisationProfileId = hopeOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Save the Children Fund", Description = "Raising funds to provide education, nutrition and healthcare to underprivileged children.", StartDate = now.AddMonths(-2), EndDate = now.AddMonths(4), TargetAmount = 50000, CurrentAmount = 250, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            var camp2 = new Campaign { OrganisationProfileId = hopeOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId, Title = "Emergency Medical Aid", Description = "Providing emergency medical supplies and treatment to those in need.", StartDate = now.AddMonths(-6), EndDate = now.AddMonths(-1), TargetAmount = 30000, CurrentAmount = 30000, Status = CampaignStatus.Completed, CreatedAt = now, UpdatedAt = now };
            var camp3 = new Campaign { OrganisationProfileId = globalOrg.OrganisationProfileId, CategoryId = catDisaster.CategoryId, Title = "Disaster Relief Ukraine", Description = "Emergency relief efforts for families displaced by conflict in Ukraine.", StartDate = now.AddMonths(-3), EndDate = now.AddMonths(6), TargetAmount = 100000, CurrentAmount = 250, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            var camp4 = new Campaign { OrganisationProfileId = globalOrg.OrganisationProfileId, CategoryId = catEducation.CategoryId, Title = "Education for All", Description = "Building schools and providing learning materials in underserved communities.", StartDate = now.AddMonths(-1), EndDate = now.AddMonths(5), TargetAmount = 25000, CurrentAmount = 75, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            var camp5 = new Campaign { OrganisationProfileId = helpingOrg.OrganisationProfileId, CategoryId = catFood.CategoryId, Title = "Feed the Hungry", Description = "Distributing meals and food packages to families facing food insecurity.", StartDate = now.AddMonths(-1), EndDate = now.AddMonths(3), TargetAmount = 40000, CurrentAmount = 50, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            var camp6 = new Campaign { OrganisationProfileId = helpingOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Children's Health Initiative", Description = "Free health screenings and vaccinations for children in rural areas.", StartDate = now.AddMonths(-8), EndDate = now.AddMonths(-2), TargetAmount = 20000, CurrentAmount = 20000, Status = CampaignStatus.Completed, CreatedAt = now, UpdatedAt = now };
            var camp7 = new Campaign { OrganisationProfileId = brightOrg.OrganisationProfileId, CategoryId = catEducation.CategoryId, Title = "Back to School", Description = "Providing school supplies and uniforms to children from low-income families.", StartDate = now.AddMonths(-1), EndDate = now.AddMonths(2), TargetAmount = 15000, CurrentAmount = 100, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            var camp8 = new Campaign { OrganisationProfileId = brightOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId, Title = "Medical Supplies Drive", Description = "Collecting and distributing medical supplies to underfunded clinics.", StartDate = now.AddDays(-15), EndDate = now.AddMonths(5), TargetAmount = 60000, CurrentAmount = 200, Status = CampaignStatus.Active, CreatedAt = now, UpdatedAt = now };
            // camp9 CurrentAmount = 1900 (matches all seeded donations below)
            var camp9  = new Campaign { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catFood.CategoryId,     Title = "Shelter & Food Program",      Description = "Providing temporary shelter and daily meals to homeless individuals and families in crisis.",    StartDate = now.AddMonths(-2),  EndDate = now.AddMonths(4),  TargetAmount = 35000, CurrentAmount = 1900,  Status = CampaignStatus.Active,    CreatedAt = now, UpdatedAt = now };
            var camp10 = new Campaign { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Youth Education Project",     Description = "After-school programs and mentoring for at-risk youth.",                                          StartDate = now.AddMonths(-10), EndDate = now.AddMonths(-3), TargetAmount = 18000, CurrentAmount = 18000, Status = CampaignStatus.Completed, CreatedAt = now, UpdatedAt = now };
            // camp11: Active (future start) — tests upcoming campaign state
            var camp11 = new Campaign { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId,   Title = "Healthcare Access Initiative", Description = "Mobile health clinics to bring basic healthcare to underserved neighbourhoods across the city.",  StartDate = now.AddMonths(1),   EndDate = now.AddMonths(7),  TargetAmount = 25000, CurrentAmount = 0,     Status = CampaignStatus.Active,    CreatedAt = now, UpdatedAt = now };
            // camp12: Cancelled — tests cancelled state in campaigns screen
            var camp12 = new Campaign { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Elderly Companion Programme",  Description = "Connecting volunteers with isolated elderly residents for regular social visits and support.",   StartDate = now.AddDays(-30),   EndDate = now.AddMonths(5),  TargetAmount = 12000, CurrentAmount = 450,   Status = CampaignStatus.Cancelled, CreatedAt = now, UpdatedAt = now };
            await context.Campaigns.AddRangeAsync(camp1, camp2, camp3, camp4, camp5, camp6, camp7, camp8, camp9, camp10, camp11, camp12);
            await context.SaveChangesAsync();

            // ── 12. VOLUNTEER JOBS ────────────────────────────────────────────────
            var job1 = new VolunteerJob { OrganisationProfileId = hopeOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Child Care Volunteer", Description = "Support children in after-school activities and homework sessions.", Requirements = "Patience, good communication skills, basic English.", StartDate = now.AddDays(7), EndDate = now.AddMonths(3), IsRemote = false, PositionsAvailable = 5, PositionsFilled = 1, Status = VolunteerJobStatus.Active, AddressId = addrHope.AddressId, CreatedAt = now, UpdatedAt = now };
            var job2 = new VolunteerJob { OrganisationProfileId = hopeOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId, Title = "Medical Camp Assistant", Description = "Assist medical staff during free health camps for low-income communities.", Requirements = "Basic first aid knowledge preferred.", StartDate = now.AddMonths(-3), EndDate = now.AddMonths(-1), IsRemote = false, PositionsAvailable = 3, PositionsFilled = 1, Status = VolunteerJobStatus.Completed, AddressId = addrHope.AddressId, CreatedAt = now, UpdatedAt = now };
            var job3 = new VolunteerJob { OrganisationProfileId = globalOrg.OrganisationProfileId, CategoryId = catFood.CategoryId, Title = "Food Distribution Helper", Description = "Help sort, pack and distribute food parcels to families in need.", Requirements = "Physical stamina, ability to work in a team.", StartDate = now.AddDays(3), EndDate = now.AddMonths(2), IsRemote = false, PositionsAvailable = 8, PositionsFilled = 1, Status = VolunteerJobStatus.Active, AddressId = addrGlobal.AddressId, CreatedAt = now, UpdatedAt = now };
            var job4 = new VolunteerJob { OrganisationProfileId = globalOrg.OrganisationProfileId, CategoryId = catEducation.CategoryId, Title = "English Tutor", Description = "Teach basic English to refugee adults and children.", Requirements = "Native or fluent English speaker, teaching experience a plus.", StartDate = now.AddDays(14), EndDate = now.AddMonths(4), IsRemote = true, PositionsAvailable = 4, PositionsFilled = 0, Status = VolunteerJobStatus.Active, CreatedAt = now, UpdatedAt = now };
            var job5 = new VolunteerJob { OrganisationProfileId = helpingOrg.OrganisationProfileId, CategoryId = catFood.CategoryId, Title = "Kitchen & Meal Prep", Description = "Prepare and serve meals at our community kitchen in Sarajevo.", Requirements = "Basic cooking skills, food hygiene awareness.", StartDate = now.AddDays(5), EndDate = now.AddMonths(3), IsRemote = false, PositionsAvailable = 6, PositionsFilled = 0, Status = VolunteerJobStatus.Active, AddressId = addrHelping.AddressId, CreatedAt = now, UpdatedAt = now };
            var job6 = new VolunteerJob { OrganisationProfileId = helpingOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId, Title = "Health Awareness Educator", Description = "Conduct workshops on hygiene and preventive healthcare in local schools.", Requirements = "Medical or nursing background preferred.", StartDate = now.AddDays(10), EndDate = now.AddMonths(2), IsRemote = false, PositionsAvailable = 3, PositionsFilled = 0, Status = VolunteerJobStatus.Active, AddressId = addrHelping.AddressId, CreatedAt = now, UpdatedAt = now };
            var job7 = new VolunteerJob { OrganisationProfileId = brightOrg.OrganisationProfileId, CategoryId = catEducation.CategoryId, Title = "After-School Tutor", Description = "Provide tutoring in math and science to students aged 10-16.", Requirements = "University degree or ongoing studies in relevant field.", StartDate = now.AddMonths(-4), EndDate = now.AddMonths(-1), IsRemote = false, PositionsAvailable = 5, PositionsFilled = 1, Status = VolunteerJobStatus.Completed, AddressId = addrBright.AddressId, CreatedAt = now, UpdatedAt = now };
            var job8 = new VolunteerJob { OrganisationProfileId = brightOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Children's Activity Leader", Description = "Lead creative and recreational activities for children aged 5-12.", Requirements = "Experience with children, creativity and energy.", StartDate = now.AddDays(7), EndDate = now.AddMonths(3), IsRemote = false, PositionsAvailable = 4, PositionsFilled = 0, Status = VolunteerJobStatus.Active, AddressId = addrBright.AddressId, CreatedAt = now, UpdatedAt = now };
            // job9: Active, PositionsFilled=3 (app9 david + appC1 john + appC2 jane)
            var job9  = new VolunteerJob { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catFood.CategoryId,     Title = "Community Food Drive",       Description = "Organise and run food donation drives across the city, coordinating with local businesses and residents.", Requirements = "Good organisational skills, driving licence a plus.",        StartDate = now.AddDays(1),    EndDate = now.AddMonths(2),  IsRemote = false, PositionsAvailable = 10, PositionsFilled = 3, Status = VolunteerJobStatus.Active,    AddressId = addrCare.AddressId, CreatedAt = now, UpdatedAt = now };
            // job10: Active, PositionsFilled=1 (appC6 james approved)
            var job10 = new VolunteerJob { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catHealth.CategoryId,   Title = "Health Screening Assistant", Description = "Assist nurses and doctors during free community health screenings.",                               Requirements = "Medical background or relevant studies preferred.",             StartDate = now.AddDays(14),   EndDate = now.AddMonths(3),  IsRemote = false, PositionsAvailable = 3,  PositionsFilled = 1, Status = VolunteerJobStatus.Active,    AddressId = addrCare.AddressId, CreatedAt = now, UpdatedAt = now };
            // job11: Completed — provides IsCompleted=true applications for review testing
            var job11 = new VolunteerJob { OrganisationProfileId = careOrg.OrganisationProfileId, CategoryId = catChildren.CategoryId, Title = "Winter Clothing Drive",       Description = "Collect, sort and distribute warm clothing to children and families ahead of the winter season.",          Requirements = "No experience required — enthusiasm and reliability essential.", StartDate = now.AddMonths(-5), EndDate = now.AddMonths(-2), IsRemote = false, PositionsAvailable = 3,  PositionsFilled = 3, Status = VolunteerJobStatus.Completed, AddressId = addrCare.AddressId, CreatedAt = now, UpdatedAt = now };
            await context.VolunteerJobs.AddRangeAsync(job1, job2, job3, job4, job5, job6, job7, job8, job9, job10, job11);
            await context.SaveChangesAsync();

            // ── 13. VOLUNTEER APPLICATIONS ────────────────────────────────────────
            var app1 = new VolunteerApplication { VolunteerJobId = job1.VolunteerJobId, UserProfileId = johnProfile.UserProfileId, CoverLetter = "I love working with children and have experience as a youth camp leader.", Status = ApplicationStatus.Approved, IsCompleted = true, AppliedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-1) };
            var app2 = new VolunteerApplication { VolunteerJobId = job4.VolunteerJobId, UserProfileId = johnProfile.UserProfileId, CoverLetter = "I am a native English speaker with tutoring experience.", Status = ApplicationStatus.Approved, IsCompleted = true, AppliedAt = now.AddMonths(-3), UpdatedAt = now.AddMonths(-2) };
            var app3 = new VolunteerApplication { VolunteerJobId = job2.VolunteerJobId, UserProfileId = janeProfile.UserProfileId, CoverLetter = "I have a nursing background and am passionate about community health.", Status = ApplicationStatus.Approved, IsCompleted = true, AppliedAt = now.AddMonths(-4), UpdatedAt = now.AddMonths(-2) };
            var app4 = new VolunteerApplication { VolunteerJobId = job6.VolunteerJobId, UserProfileId = janeProfile.UserProfileId, CoverLetter = "I would love to educate communities on health and hygiene practices.", Status = ApplicationStatus.Pending, IsCompleted = false, AppliedAt = now.AddDays(-5), UpdatedAt = now.AddDays(-5) };
            var app5 = new VolunteerApplication { VolunteerJobId = job3.VolunteerJobId, UserProfileId = mikeProfile.UserProfileId, CoverLetter = "I have helped organise food drives in my local community before.", Status = ApplicationStatus.Approved, IsCompleted = true, AppliedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-1) };
            var app6 = new VolunteerApplication { VolunteerJobId = job7.VolunteerJobId, UserProfileId = emilyProfile.UserProfileId, CoverLetter = "Currently studying mathematics education, eager to give back.", Status = ApplicationStatus.Approved, IsCompleted = true, AppliedAt = now.AddMonths(-4), UpdatedAt = now.AddMonths(-2) };
            var app7 = new VolunteerApplication { VolunteerJobId = job5.VolunteerJobId, UserProfileId = chrisProfile.UserProfileId, CoverLetter = "I want to help prepare meals for those who need it most.", Status = ApplicationStatus.Rejected, RejectionReason = "Position has been filled by other applicants.", IsCompleted = false, AppliedAt = now.AddDays(-10), UpdatedAt = now.AddDays(-7) };
            var app8 = new VolunteerApplication { VolunteerJobId = job8.VolunteerJobId, UserProfileId = sarahProfile.UserProfileId, CoverLetter = "I have experience leading creative workshops for young children.", Status = ApplicationStatus.Pending, IsCompleted = false, AppliedAt = now.AddDays(-3), UpdatedAt = now.AddDays(-3) };
            var app9  = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId,  UserProfileId = davidProfile.UserProfileId, CoverLetter = "I have strong logistics experience and a valid driving licence.",                                    Status = ApplicationStatus.Approved, IsCompleted = true,  AppliedAt = now.AddMonths(-1), UpdatedAt = now.AddDays(-14) };
            var app10 = new VolunteerApplication { VolunteerJobId = job10.VolunteerJobId, UserProfileId = lisaProfile.UserProfileId,  CoverLetter = "I am a medical student and would love to assist during screenings.",                                Status = ApplicationStatus.Pending,  IsCompleted = false, AppliedAt = now.AddDays(-2),   UpdatedAt = now.AddDays(-2) };

            // careshare_org — job9 (Community Food Drive) — varied statuses
            var appC1 = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId, UserProfileId = johnProfile.UserProfileId,  CoverLetter = "I regularly organise neighbourhood charity events and have a full driving licence.",                    Status = ApplicationStatus.Approved,  IsCompleted = true,  AppliedAt = now.AddMonths(-1), UpdatedAt = now.AddDays(-20) };
            var appC2 = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId, UserProfileId = janeProfile.UserProfileId,  CoverLetter = "Community work is my passion — I volunteered for three food drives last year.",                          Status = ApplicationStatus.Approved,  IsCompleted = true,  AppliedAt = now.AddMonths(-1), UpdatedAt = now.AddDays(-18) };
            var appC3 = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId, UserProfileId = emilyProfile.UserProfileId, CoverLetter = "I am very motivated and a quick learner willing to take on any task needed.",                            Status = ApplicationStatus.Rejected,  IsCompleted = false, AppliedAt = now.AddDays(-12),  UpdatedAt = now.AddDays(-9),  RejectionReason = "We have filled all available positions for this role." };
            var appC4 = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId, UserProfileId = chrisProfile.UserProfileId, CoverLetter = "I have a van and experience delivering donations — happy to help in any capacity.",                      Status = ApplicationStatus.Pending,   IsCompleted = false, AppliedAt = now.AddDays(-4),   UpdatedAt = now.AddDays(-4) };
            var appC5 = new VolunteerApplication { VolunteerJobId = job9.VolunteerJobId, UserProfileId = sarahProfile.UserProfileId, CoverLetter = "Volunteering with the community is something I deeply care about.",                                       Status = ApplicationStatus.Pending,   IsCompleted = false, AppliedAt = now.AddDays(-2),   UpdatedAt = now.AddDays(-2) };

            // careshare_org — job10 (Health Screening Assistant)
            var appC6 = new VolunteerApplication { VolunteerJobId = job10.VolunteerJobId, UserProfileId = jamesProfile.UserProfileId, CoverLetter = "I am in my final year of nursing studies and keen to gain practical field experience.",                 Status = ApplicationStatus.Approved,  IsCompleted = false, AppliedAt = now.AddDays(-8),   UpdatedAt = now.AddDays(-5) };
            var appC7 = new VolunteerApplication { VolunteerJobId = job10.VolunteerJobId, UserProfileId = mikeProfile.UserProfileId,  CoverLetter = "I have a biology degree and a genuine desire to give back to the community.",                           Status = ApplicationStatus.Pending,   IsCompleted = false, AppliedAt = now.AddDays(-3),   UpdatedAt = now.AddDays(-3) };
            var appC8 = new VolunteerApplication { VolunteerJobId = job10.VolunteerJobId, UserProfileId = emmaProfile.UserProfileId,  CoverLetter = "I am passionate about public health and would love the opportunity to help.",                            Status = ApplicationStatus.Rejected,  IsCompleted = false, AppliedAt = now.AddDays(-6),   UpdatedAt = now.AddDays(-4),  RejectionReason = "Applicant does not meet the minimum medical background requirement." };

            // careshare_org — job11 (Winter Clothing Drive, Completed — all 3 approved & done, eligible for reviews)
            var appCC1 = new VolunteerApplication { VolunteerJobId = job11.VolunteerJobId, UserProfileId = lisaProfile.UserProfileId,  CoverLetter = "I want to help make sure no child goes cold this winter.",                                             Status = ApplicationStatus.Approved,  IsCompleted = true,  AppliedAt = now.AddMonths(-5), UpdatedAt = now.AddMonths(-2) };
            var appCC2 = new VolunteerApplication { VolunteerJobId = job11.VolunteerJobId, UserProfileId = chrisProfile.UserProfileId, CoverLetter = "I have experience sorting and distributing donations at a local shelter.",                              Status = ApplicationStatus.Approved,  IsCompleted = true,  AppliedAt = now.AddMonths(-5), UpdatedAt = now.AddMonths(-2) };
            var appCC3 = new VolunteerApplication { VolunteerJobId = job11.VolunteerJobId, UserProfileId = emilyProfile.UserProfileId, CoverLetter = "Happy to help with any physical tasks — sorting, packing, delivering.",                                 Status = ApplicationStatus.Approved,  IsCompleted = true,  AppliedAt = now.AddMonths(-5), UpdatedAt = now.AddMonths(-2) };

            await context.VolunteerApplications.AddRangeAsync(
                app1, app2, app3, app4, app5, app6, app7, app8, app9, app10,
                appC1, appC2, appC3, appC4, appC5,
                appC6, appC7, appC8,
                appCC1, appCC2, appCC3);
            await context.SaveChangesAsync();

            // ── 14. DONATIONS ─────────────────────────────────────────────────────
            // Other campaigns
            await context.Donations.AddRangeAsync(
                new Donation { CampaignId = camp1.CampaignId, UserProfileId = johnProfile.UserProfileId,  Amount = 100, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-10), CreatedAt = now.AddDays(-10) },
                new Donation { CampaignId = camp1.CampaignId, UserProfileId = sarahProfile.UserProfileId, Amount = 150, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-3),  CreatedAt = now.AddDays(-3) },
                new Donation { CampaignId = camp3.CampaignId, UserProfileId = janeProfile.UserProfileId,  Amount = 250, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-8),  CreatedAt = now.AddDays(-8) },
                new Donation { CampaignId = camp4.CampaignId, UserProfileId = emilyProfile.UserProfileId, Amount = 75,  IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-5),  CreatedAt = now.AddDays(-5) },
                new Donation { CampaignId = camp5.CampaignId, UserProfileId = mikeProfile.UserProfileId,  Amount = 50,  IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-6),  CreatedAt = now.AddDays(-6) },
                new Donation { CampaignId = camp7.CampaignId, UserProfileId = davidProfile.UserProfileId, Amount = 100, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-2),  CreatedAt = now.AddDays(-2) },
                new Donation { CampaignId = camp8.CampaignId, UserProfileId = chrisProfile.UserProfileId, Amount = 200, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-4),  CreatedAt = now.AddDays(-4) }
            );

            // careshare_org — camp9 (Shelter & Food Program) — 8 donations totalling 1900, matching CurrentAmount
            await context.Donations.AddRangeAsync(
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = emmaProfile.UserProfileId,  Amount = 300, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-1),  CreatedAt = now.AddDays(-1) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = johnProfile.UserProfileId,  Amount = 500, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-3),  CreatedAt = now.AddDays(-3) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = janeProfile.UserProfileId,  Amount = 250, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-5),  CreatedAt = now.AddDays(-5) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = chrisProfile.UserProfileId, Amount = 150, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-7),  CreatedAt = now.AddDays(-7) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = null,                       Amount = 200, IsAnonymous = true,  Status = DonationStatus.Success, DonationDateTime = now.AddDays(-9),  CreatedAt = now.AddDays(-9) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = jamesProfile.UserProfileId, Amount = 75,  IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-11), CreatedAt = now.AddDays(-11) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = null,                       Amount = 300, IsAnonymous = true,  Status = DonationStatus.Success, DonationDateTime = now.AddDays(-14), CreatedAt = now.AddDays(-14) },
                new Donation { CampaignId = camp9.CampaignId, UserProfileId = emilyProfile.UserProfileId, Amount = 125, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-18), CreatedAt = now.AddDays(-18) }
            );

            // careshare_org — camp12 (Elderly Companion, Paused) — 2 donations before pause, matching CurrentAmount 450
            await context.Donations.AddRangeAsync(
                new Donation { CampaignId = camp12.CampaignId, UserProfileId = sarahProfile.UserProfileId, Amount = 250, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-20), CreatedAt = now.AddDays(-20) },
                new Donation { CampaignId = camp12.CampaignId, UserProfileId = davidProfile.UserProfileId, Amount = 200, IsAnonymous = false, Status = DonationStatus.Success, DonationDateTime = now.AddDays(-25), CreatedAt = now.AddDays(-25) }
            );
            await context.SaveChangesAsync();

            // ── 15. REVIEWS ───────────────────────────────────────────────────────
            // Other organisations
            await context.Reviews.AddRangeAsync(
                new Review { VolunteerApplicationId = app1.VolunteerApplicationId, OrganisationProfileId = hopeOrg.OrganisationProfileId,   UserProfileId = johnProfile.UserProfileId,  Rating = 5, Comment = "Amazing experience volunteering with this organisation. Very well organised and impactful.",   CreatedAt = now.AddMonths(-1), UpdatedAt = now.AddMonths(-1) },
                new Review { VolunteerApplicationId = app2.VolunteerApplicationId, OrganisationProfileId = globalOrg.OrganisationProfileId,  UserProfileId = johnProfile.UserProfileId,  Rating = 4, Comment = "Great work and very well organised. The team was supportive throughout.",                     CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) },
                new Review { VolunteerApplicationId = app3.VolunteerApplicationId, OrganisationProfileId = hopeOrg.OrganisationProfileId,   UserProfileId = janeProfile.UserProfileId,  Rating = 5, Comment = "Incredibly rewarding experience. I felt like I truly made a difference.",                     CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) },
                new Review { VolunteerApplicationId = app5.VolunteerApplicationId, OrganisationProfileId = globalOrg.OrganisationProfileId,  UserProfileId = mikeProfile.UserProfileId,  Rating = 4, Comment = "Good coordination and very impactful work. Would volunteer again.",                           CreatedAt = now.AddMonths(-1), UpdatedAt = now.AddMonths(-1) },
                new Review { VolunteerApplicationId = app6.VolunteerApplicationId, OrganisationProfileId = brightOrg.OrganisationProfileId, UserProfileId = emilyProfile.UserProfileId, Rating = 5, Comment = "Wonderful team and a great cause. The children were so enthusiastic.",                         CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) }
            );

            // careshare_org — 6 reviews across ratings 3–5 for a rich reviews screen
            await context.Reviews.AddRangeAsync(
                // job9 completed applications
                new Review { VolunteerApplicationId = app9.VolunteerApplicationId,   OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = davidProfile.UserProfileId, Rating = 4, Comment = "Very professional and welcoming organisation. The food drive was incredibly well run — I'll definitely volunteer again.",                                    CreatedAt = now.AddDays(-14), UpdatedAt = now.AddDays(-14) },
                new Review { VolunteerApplicationId = appC1.VolunteerApplicationId,  OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = johnProfile.UserProfileId,  Rating = 5, Comment = "Exceptional experience from start to finish. The coordinators were always available, logistics were smooth and the impact was visible immediately.",       CreatedAt = now.AddDays(-19), UpdatedAt = now.AddDays(-19) },
                new Review { VolunteerApplicationId = appC2.VolunteerApplicationId,  OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = janeProfile.UserProfileId,  Rating = 4, Comment = "Really enjoyed contributing to this cause. The team was warm and supportive. Would have given 5 stars if the initial briefing had been a bit more detailed.", CreatedAt = now.AddDays(-17), UpdatedAt = now.AddDays(-17) },
                // job11 completed applications
                new Review { VolunteerApplicationId = appCC1.VolunteerApplicationId, OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = lisaProfile.UserProfileId,  Rating = 5, Comment = "One of the most rewarding things I have ever done. Seeing families receive warm clothing before winter was truly moving. Highly recommended.",             CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) },
                new Review { VolunteerApplicationId = appCC2.VolunteerApplicationId, OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = chrisProfile.UserProfileId, Rating = 3, Comment = "Good initiative but organisation could be improved — there were delays and communication gaps. The cause itself is absolutely worth supporting though.",    CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) },
                new Review { VolunteerApplicationId = appCC3.VolunteerApplicationId, OrganisationProfileId = careOrg.OrganisationProfileId, UserProfileId = emilyProfile.UserProfileId, Rating = 4, Comment = "Solid volunteer programme. Tasks were clearly explained and I always felt useful. The team spirit was great and I made some wonderful connections.",        CreatedAt = now.AddMonths(-2), UpdatedAt = now.AddMonths(-2) }
            );
            await context.SaveChangesAsync();
        }

        private static User CreateUser(string username, string email, string password, UserType userType)
        {
            var (salt, hash) = HashPassword(password);
            return new User
            {
                Username = username,
                Email = email,
                PasswordSalt = salt,
                PasswordHash = hash,
                UserType = userType,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        }

        private static (string salt, string hash) HashPassword(string password)
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            var hashBytes = Rfc2898DeriveBytes.Pbkdf2(password, saltBytes, 100_000, HashAlgorithmName.SHA256, 32);
            return (Convert.ToBase64String(saltBytes), Convert.ToBase64String(hashBytes));
        }
    }
}
