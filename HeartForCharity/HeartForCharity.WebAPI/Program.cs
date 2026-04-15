using FluentValidation;
using FluentValidation.AspNetCore;
using HeartForCharity.Model.Validators;
using HeartForCharity.Services;
using HeartForCharity.Services.Database;
using EasyNetQ;
using HeartForCharity.Services.CampaignStateMachine;
using HeartForCharity.Services.VolunteerApplicationStateMachine;
using HeartForCharity.Services.VolunteerJobStateMachine;
using HeartForCharity.WebAPI.Services;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Referentni podaci
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ISkillService, SkillService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IOrganisationTypeService, OrganisationTypeService>();
builder.Services.AddScoped<IAddressService, AddressService>();

// Korisnici
builder.Services.AddScoped<IUserService, UserService>();

// Profili
builder.Services.AddScoped<IUserProfileService, UserProfileService>();
builder.Services.AddScoped<IOrganisationProfileService, OrganisationProfileService>();

// Glavni entiteti
builder.Services.AddScoped<ICampaignService, CampaignService>();
builder.Services.AddScoped<ICampaignMediaService, CampaignMediaService>();
builder.Services.AddScoped<IVolunteerJobService, VolunteerJobService>();
builder.Services.AddScoped<IVolunteerApplicationService, VolunteerApplicationService>();
builder.Services.AddScoped<IDonationService, DonationService>();
builder.Services.AddScoped<IVolunteerSkillService, VolunteerSkillService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

// Volunteer application state machine
builder.Services.AddScoped<BaseApplicationState>();
builder.Services.AddScoped<PendingApplicationState>();
builder.Services.AddScoped<ApprovedApplicationState>();
builder.Services.AddScoped<RejectedApplicationState>();
builder.Services.AddScoped<WithdrawnApplicationState>();

// Campaign state machine
builder.Services.AddScoped<BaseCampaignState>();
builder.Services.AddScoped<ActiveCampaignState>();
builder.Services.AddScoped<CompletedCampaignState>();
builder.Services.AddScoped<CancelledCampaignState>();

// Volunteer job state machine
builder.Services.AddScoped<BaseVolunteerJobState>();
builder.Services.AddScoped<ActiveVolunteerJobState>();
builder.Services.AddScoped<CompletedVolunteerJobState>();
builder.Services.AddScoped<CancelledVolunteerJobState>();

builder.Services.RegisterEasyNetQ("host=localhost;username=guest;password=guest");

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.AddSingleton<IPayPalService, PayPalService>();

builder.Services.AddMapster();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=210002;Trusted_Connection=True;TrustServerCertificate=True";

builder.Services.AddHeartForCharityDatabase(connectionString);

var jwtKey = builder.Configuration["Jwt:Key"]!;
var jwtIssuer = builder.Configuration["Jwt:Issuer"]!;
var jwtAudience = builder.Configuration["Jwt:Audience"]!;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddControllers(options =>
{
    options.Filters.Add<HeartForCharity.WebAPI.Filters.ExceptionFilter>();
});
builder.Services.AddFluentValidationAutoValidation(config =>
{
    config.DisableDataAnnotationsValidation = true;
});
builder.Services.AddValidatorsFromAssemblyContaining<CampaignInsertRequestValidator>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your JWT token. Example: eyJhbGci..."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dataContext = scope.ServiceProvider.GetRequiredService<HeartForCharityDbContext>();
    dataContext.Database.Migrate();
    await DatabaseSeeder.SeedAsync(dataContext);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
