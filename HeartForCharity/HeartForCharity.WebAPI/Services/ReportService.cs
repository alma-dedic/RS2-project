using HeartForCharity.Model.Enums;
using HeartForCharity.Model.Requests;
using HeartForCharity.Services;
using HeartForCharity.Services.Database;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace HeartForCharity.WebAPI.Services
{
    public class ReportService : IReportService
    {
        private readonly HeartForCharityDbContext _context;
        private readonly ICurrentUserService _currentUserService;
        private readonly string? _logoPath;

        private const string BrandColor = "#D1493F";
        private const string LightGray = "#F3F4F6";
        private const string DarkText = "#1A1A2E";
        private const string GrayText = "#6B7280";

        public ReportService(HeartForCharityDbContext context, ICurrentUserService currentUserService, IWebHostEnvironment env)
        {
            _context = context;
            _currentUserService = currentUserService;
            var path = Path.Combine(env.WebRootPath, "logo.png");
            _logoPath = File.Exists(path) ? path : null;
        }

        private async Task<OrganisationProfile> GetOrgProfileAsync()
        {
            var org = await _context.OrganisationProfiles
                .FirstOrDefaultAsync(op => op.UserId == _currentUserService.UserId);
            if (org == null) throw new Exception("Organisation profile not found.");
            return org;
        }

        // ─── DONATIONS ───────────────────────────────────────────────────────────

        public async Task<byte[]> GenerateDonationsReportAsync(DonationsReportRequest request)
        {
            var org = await GetOrgProfileAsync();

            var campaignIds = await _context.Campaigns
                .Where(c => c.OrganisationProfileId == org.OrganisationProfileId && c.DeletedAt == null)
                .Select(c => c.CampaignId)
                .ToListAsync();

            var query = _context.Donations
                .Include(d => d.Campaign)
                .Include(d => d.UserProfile)
                .Where(d => campaignIds.Contains(d.CampaignId) && d.Status == DonationStatus.Success);

            if (request.CampaignId.HasValue)
                query = query.Where(d => d.CampaignId == request.CampaignId.Value);
            if (request.FromDate.HasValue)
                query = query.Where(d => d.DonationDateTime >= request.FromDate.Value);
            if (request.ToDate.HasValue)
                query = query.Where(d => d.DonationDateTime <= request.ToDate.Value.AddDays(1));

            var donations = await query.OrderByDescending(d => d.DonationDateTime).ToListAsync();
            var totalAmount = donations.Sum(d => d.Amount);

            var dateRange = BuildDateRangeLabel(request.FromDate, request.ToDate);

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    ApplyPageDefaults(page);

                    page.Header().Element(c => BuildHeader(c, org.Name, "Donations Report", dateRange, _logoPath));

                    page.Content().PaddingVertical(16).Column(col =>
                    {
                        col.Item().Row(row =>
                        {
                            row.RelativeItem().Text($"Total donations: {donations.Count}").FontSize(11).FontColor(GrayText);
                            row.RelativeItem().AlignRight().Text($"Total raised: €{totalAmount:N2}").FontSize(11).Bold().FontColor(BrandColor);
                        });
                        col.Item().PaddingTop(12).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            BuildTableHeader(table, ["Donor", "Campaign", "Amount", "Date"]);

                            for (int i = 0; i < donations.Count; i++)
                            {
                                var d = donations[i];
                                var bg = i % 2 == 0 ? "#FFFFFF" : LightGray;
                                var donor = d.IsAnonymous || d.UserProfile == null
                                    ? "Anonymous"
                                    : $"{d.UserProfile.FirstName} {d.UserProfile.LastName}";

                                BuildTableRow(table, bg,
                                [
                                    donor,
                                    d.Campaign?.Title ?? "-",
                                    $"€{d.Amount:N2}",
                                    d.DonationDateTime.ToString("dd MMM yyyy"),
                                ]);
                            }

                            if (donations.Count == 0)
                                BuildEmptyRow(table, 4);
                        });
                    });

                    page.Footer().Element(BuildFooter);
                });
            }).GeneratePdf();
        }

        // ─── CAMPAIGNS ───────────────────────────────────────────────────────────

        public async Task<byte[]> GenerateCampaignsReportAsync(CampaignsReportRequest request)
        {
            var org = await GetOrgProfileAsync();

            var query = _context.Campaigns
                .Where(c => c.OrganisationProfileId == org.OrganisationProfileId && c.DeletedAt == null);

            if (!string.IsNullOrWhiteSpace(request.Status) &&
                Enum.TryParse<CampaignStatus>(request.Status, out var statusEnum))
                query = query.Where(c => c.Status == statusEnum);

            var campaigns = await query.OrderByDescending(c => c.CreatedAt).ToListAsync();
            var statusLabel = string.IsNullOrWhiteSpace(request.Status) ? "All" : request.Status;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    ApplyPageDefaults(page);

                    page.Header().Element(c => BuildHeader(c, org.Name, "Campaigns Report", $"Status: {statusLabel}", _logoPath));

                    page.Content().PaddingVertical(16).Column(col =>
                    {
                        col.Item().Text($"Total campaigns: {campaigns.Count}").FontSize(11).FontColor(GrayText);
                        col.Item().PaddingTop(12).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(4);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            BuildTableHeader(table, ["Title", "Status", "Target", "Raised", "Progress"]);

                            for (int i = 0; i < campaigns.Count; i++)
                            {
                                var c = campaigns[i];
                                var bg = i % 2 == 0 ? "#FFFFFF" : LightGray;
                                var progress = c.TargetAmount > 0
                                    ? $"{(c.CurrentAmount / c.TargetAmount * 100):N0}%"
                                    : "0%";

                                BuildTableRow(table, bg,
                                [
                                    c.Title,
                                    c.Status.ToString(),
                                    $"€{c.TargetAmount:N2}",
                                    $"€{c.CurrentAmount:N2}",
                                    progress,
                                ]);
                            }

                            if (campaigns.Count == 0)
                                BuildEmptyRow(table, 5);
                        });
                    });

                    page.Footer().Element(BuildFooter);
                });
            }).GeneratePdf();
        }

        // ─── VOLUNTEERS ──────────────────────────────────────────────────────────

        public async Task<byte[]> GenerateVolunteersReportAsync(VolunteersReportRequest request)
        {
            var org = await GetOrgProfileAsync();

            var jobIds = await _context.VolunteerJobs
                .Where(j => j.OrganisationProfileId == org.OrganisationProfileId && j.DeletedAt == null)
                .Select(j => j.VolunteerJobId)
                .ToListAsync();

            var query = _context.VolunteerApplications
                .Include(a => a.UserProfile)
                .Include(a => a.VolunteerJob)
                .Where(a => jobIds.Contains(a.VolunteerJobId) && a.Status == ApplicationStatus.Approved);

            if (request.VolunteerJobId.HasValue)
                query = query.Where(a => a.VolunteerJobId == request.VolunteerJobId.Value);

            var applications = await query.OrderByDescending(a => a.AppliedAt).ToListAsync();

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    ApplyPageDefaults(page);

                    page.Header().Element(c => BuildHeader(c, org.Name, "Volunteers Report", "Approved volunteers", _logoPath));

                    page.Content().PaddingVertical(16).Column(col =>
                    {
                        col.Item().Text($"Total approved volunteers: {applications.Count}").FontSize(11).FontColor(GrayText);
                        col.Item().PaddingTop(12).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(2);
                            });

                            BuildTableHeader(table, ["Volunteer", "Job Title", "Approved On"]);

                            for (int i = 0; i < applications.Count; i++)
                            {
                                var a = applications[i];
                                var bg = i % 2 == 0 ? "#FFFFFF" : LightGray;
                                var name = a.UserProfile != null
                                    ? $"{a.UserProfile.FirstName} {a.UserProfile.LastName}"
                                    : "Unknown";

                                BuildTableRow(table, bg,
                                [
                                    name,
                                    a.VolunteerJob?.Title ?? "-",
                                    a.AppliedAt.ToString("dd MMM yyyy"),
                                ]);
                            }

                            if (applications.Count == 0)
                                BuildEmptyRow(table, 3);
                        });
                    });

                    page.Footer().Element(BuildFooter);
                });
            }).GeneratePdf();
        }

        // ─── HELPERS ─────────────────────────────────────────────────────────────

        private static void ApplyPageDefaults(PageDescriptor page)
        {
            page.Size(PageSizes.A4.Landscape());
            page.MarginHorizontal(36);
            page.MarginVertical(28);
            page.DefaultTextStyle(t => t.FontFamily("Arial").FontSize(10).FontColor(DarkText));
        }

        private static void BuildHeader(IContainer container, string orgName, string title, string subtitle, string? logoPath)
        {
            container.BorderBottom(2).BorderColor(BrandColor).PaddingBottom(12).Row(row =>
            {
                row.RelativeItem().Column(col =>
                {
                    col.Item().Text(title).FontSize(18).Bold().FontColor(BrandColor);
                    col.Item().Text(subtitle).FontSize(10).FontColor(GrayText);
                });
                row.RelativeItem().AlignRight().Column(col =>
                {
                    if (logoPath != null)
                        col.Item().AlignRight().Height(36).Image(logoPath).FitHeight();
                    col.Item().AlignRight().Text(orgName).FontSize(10).FontColor(GrayText);
                    col.Item().AlignRight().Text($"Generated: {DateTime.UtcNow:dd MMM yyyy HH:mm} UTC")
                        .FontSize(9).FontColor(GrayText);
                });
            });
        }

        private static void BuildTableHeader(TableDescriptor table, string[] columns)
        {
            table.Header(header =>
            {
                foreach (var col in columns)
                {
                    header.Cell()
                        .Background(BrandColor)
                        .Padding(8)
                        .Text(col)
                        .FontColor("#FFFFFF")
                        .Bold()
                        .FontSize(10);
                }
            });
        }

        private static void BuildTableRow(TableDescriptor table, string bg, string[] values)
        {
            foreach (var val in values)
            {
                table.Cell()
                    .Background(bg)
                    .BorderBottom(1).BorderColor(LightGray)
                    .Padding(8)
                    .Text(val)
                    .FontSize(9)
                    .FontColor(DarkText);
            }
        }

        private static void BuildEmptyRow(TableDescriptor table, int colCount)
        {
            for (int i = 0; i < colCount; i++)
            {
                var cell = table.Cell().Background("#FFFFFF").Padding(12);
                if (i == 0)
                    cell.Text("No data found.").FontColor(GrayText).FontSize(9);
                else
                    cell.Text("");
            }
        }

        private static void BuildFooter(IContainer container)
        {
            container.PaddingTop(8).BorderTop(1).BorderColor(LightGray).Row(row =>
            {
                row.RelativeItem().Text("HeartForCharity — Confidential").FontSize(8).FontColor(GrayText);
                row.RelativeItem().AlignRight().Text(text =>
                {
                    text.Span("Page ").FontSize(8).FontColor(GrayText);
                    text.CurrentPageNumber().FontSize(8).FontColor(GrayText);
                    text.Span(" of ").FontSize(8).FontColor(GrayText);
                    text.TotalPages().FontSize(8).FontColor(GrayText);
                });
            });
        }

        private static string BuildDateRangeLabel(DateTime? from, DateTime? to)
        {
            if (from == null && to == null) return "All time";
            if (from == null) return $"Up to {to:dd MMM yyyy}";
            if (to == null) return $"From {from:dd MMM yyyy}";
            return $"{from:dd MMM yyyy} — {to:dd MMM yyyy}";
        }
    }
}
