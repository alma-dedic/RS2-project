using HeartForCharity.Services;
using HeartForCharity.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UploadController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        private readonly HeartForCharityDbContext _context;
        private readonly ICurrentUserService _currentUserService;

        private static readonly string[] ImageExtensions = [".jpg", ".jpeg", ".png", ".webp"];
        private static readonly string[] ImageContentTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
        private const string DocumentExtension = ".pdf";
        private const string DocumentContentType = "application/pdf";
        private const long MaxFileSize = 5 * 1024 * 1024;

        private const string PublicFolder = "public";
        private const string PrivateFolder = "private";

        public UploadController(
            IWebHostEnvironment env,
            HeartForCharityDbContext context,
            ICurrentUserService currentUserService)
        {
            _env = env;
            _context = context;
            _currentUserService = currentUserService;
        }

        [HttpPost("image")]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file provided.");

            if (file.Length > MaxFileSize)
                return BadRequest("File size must not exceed 5MB.");

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!ImageExtensions.Contains(ext))
                return BadRequest("Only .jpg, .jpeg, .png and .webp files are allowed.");

            if (!ImageContentTypes.Contains(file.ContentType?.ToLowerInvariant()))
                return BadRequest("Content type does not match an allowed image format.");

            if (!await IsValidImageContentAsync(file))
                return BadRequest("File content does not match a supported image format.");

            var fileName = await SaveFileAsync(file, PublicFolder, ext);
            var url = $"{Request.Scheme}://{Request.Host}/api/upload/{PublicFolder}/{fileName}";
            return Ok(new { url });
        }

        [HttpPost("document")]
        public async Task<IActionResult> UploadDocument(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file provided.");

            if (file.Length > MaxFileSize)
                return BadRequest("File size must not exceed 5MB.");

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (ext != DocumentExtension)
                return BadRequest("Only .pdf files are allowed.");

            if (!string.Equals(file.ContentType, DocumentContentType, StringComparison.OrdinalIgnoreCase))
                return BadRequest("Content type does not match an allowed document format.");

            if (!await IsValidPdfContentAsync(file))
                return BadRequest("File content does not match a PDF format.");

            var fileName = await SaveFileAsync(file, PrivateFolder, ext);
            var url = $"{Request.Scheme}://{Request.Host}/api/upload/{PrivateFolder}/{fileName}";
            return Ok(new { url });
        }

        [HttpGet("public/{fileName}")]
        [AllowAnonymous]
        public IActionResult DownloadPublic(string fileName)
        {
            var sanitized = Path.GetFileName(fileName);
            if (string.IsNullOrEmpty(sanitized))
                return BadRequest();

            var path = Path.Combine(_env.WebRootPath, "uploads", PublicFolder, sanitized);
            if (!System.IO.File.Exists(path))
                return NotFound();

            var ext = Path.GetExtension(sanitized).ToLowerInvariant();
            var contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };

            return PhysicalFile(path, contentType);
        }

        [HttpGet("private/{fileName}")]
        public async Task<IActionResult> DownloadPrivate(string fileName)
        {
            var sanitized = Path.GetFileName(fileName);
            if (string.IsNullOrEmpty(sanitized))
                return BadRequest();

            var path = Path.Combine(_env.WebRootPath, "uploads", PrivateFolder, sanitized);
            if (!System.IO.File.Exists(path))
                return NotFound();

            if (!await CanAccessPrivateFileAsync(sanitized))
                return Forbid();

            return PhysicalFile(path, DocumentContentType);
        }

        private async Task<bool> CanAccessPrivateFileAsync(string fileName)
        {
            if (string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase))
                return true;

            var currentUserId = _currentUserService.UserId;
            if (currentUserId == 0)
                return false;

            var suffix = $"/{fileName}";

            var application = await _context.VolunteerApplications
                .Include(a => a.UserProfile)
                .Include(a => a.VolunteerJob)
                    .ThenInclude(j => j.OrganisationProfile)
                .FirstOrDefaultAsync(a => a.ResumeUrl != null && a.ResumeUrl.EndsWith(suffix));

            if (application == null)
                return false;

            if (application.UserProfile?.UserId == currentUserId)
                return true;

            if (application.VolunteerJob?.OrganisationProfile?.UserId == currentUserId)
                return true;

            return false;
        }

        private async Task<string> SaveFileAsync(IFormFile file, string subFolder, string ext)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads", subFolder);
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);

            return fileName;
        }

        private static async Task<bool> IsValidImageContentAsync(IFormFile file)
        {
            var header = new byte[12];
            using var stream = file.OpenReadStream();
            var bytesRead = await stream.ReadAsync(header, 0, header.Length);
            if (bytesRead < 4) return false;

            if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
                return true;

            if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
                header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
                return true;

            if (bytesRead >= 12 &&
                header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
                header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
                return true;

            return false;
        }

        private static async Task<bool> IsValidPdfContentAsync(IFormFile file)
        {
            var header = new byte[4];
            using var stream = file.OpenReadStream();
            var bytesRead = await stream.ReadAsync(header, 0, header.Length);
            if (bytesRead < 4) return false;

            return header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46;
        }
    }
}
