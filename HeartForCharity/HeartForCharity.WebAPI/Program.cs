using FluentValidation;
using FluentValidation.AspNetCore;
using HeartForCharity.Model.Validators;
using HeartForCharity.Services;
using HeartForCharity.Services.Database;
using HeartForCharity.Services.CampaignStateMachine;
using HeartForCharity.Services.VolunteerApplicationStateMachine;
using HeartForCharity.Services.VolunteerJobStateMachine;
using HeartForCharity.WebAPI.Services;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Threading.RateLimiting;

DotNetEnv.Env.Load();

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();


builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ISkillService, SkillService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IOrganisationTypeService, OrganisationTypeService>();
builder.Services.AddScoped<IAddressService, AddressService>();

builder.Services.AddScoped<IUserService, UserService>();

builder.Services.AddScoped<IUserProfileService, UserProfileService>();
builder.Services.AddScoped<IOrganisationProfileService, OrganisationProfileService>();

builder.Services.AddScoped<ICampaignService, CampaignService>();
builder.Services.AddScoped<ICampaignMediaService, CampaignMediaService>();
builder.Services.AddScoped<IVolunteerJobService, VolunteerJobService>();
builder.Services.AddScoped<IVolunteerApplicationService, VolunteerApplicationService>();
builder.Services.AddScoped<IDonationService, DonationService>();
builder.Services.AddScoped<IVolunteerSkillService, VolunteerSkillService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IRecommenderService, RecommenderService>();

builder.Services.AddScoped<BaseApplicationState>();
builder.Services.AddScoped<PendingApplicationState>();
builder.Services.AddScoped<ApprovedApplicationState>();
builder.Services.AddScoped<RejectedApplicationState>();
builder.Services.AddScoped<WithdrawnApplicationState>();

builder.Services.AddScoped<BaseCampaignState>();
builder.Services.AddScoped<ActiveCampaignState>();
builder.Services.AddScoped<CompletedCampaignState>();
builder.Services.AddScoped<CancelledCampaignState>();

builder.Services.AddScoped<BaseVolunteerJobState>();
builder.Services.AddScoped<ActiveVolunteerJobState>();
builder.Services.AddScoped<CompletedVolunteerJobState>();
builder.Services.AddScoped<CancelledVolunteerJobState>();

builder.Services.RegisterEasyNetQ(builder.Configuration["RabbitMQ:Connection"]!);

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("login", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 0;
    });

    options.RejectionStatusCode = 429;
});

builder.Services.AddMemoryCache();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.AddSingleton<IPayPalService, PayPalService>();

builder.Services.AddMapster();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

builder.Services.AddHeartForCharityDatabase(connectionString);

var jwtKey = builder.Configuration["Jwt:Key"]!;
var jwtIssuer = builder.Configuration["Jwt:Issuer"]!;
var jwtAudience = builder.Configuration["Jwt:Audience"]!;

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(
                  "http://localhost:8080",   // Flutter web
                  "http://localhost:3000",   // desktop dev
                  "http://localhost:5145",   // local API (same-origin Swagger)
                  "http://10.0.2.2:5145"    // Android emulator → host
              )
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

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
}).AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
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

QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dataContext = scope.ServiceProvider.GetRequiredService<HeartForCharityDbContext>();
    dataContext.Database.Migrate();
    await DatabaseSeeder.SeedAsync(dataContext);
}

app.UseSwagger();
app.UseSwaggerUI();

// Block direct access to /uploads/ — files are served through /api/upload/{fileName} with [Authorize]
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/uploads"))
    {
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        await context.Response.WriteAsync("Unauthorized. Use /api/upload/{fileName} to access files.");
        return;
    }
    await next();
});

app.UseStaticFiles();
app.UseRouting();
app.UseCors();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run("http://0.0.0.0:5145");
