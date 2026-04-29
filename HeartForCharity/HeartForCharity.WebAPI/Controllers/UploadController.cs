using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UploadController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;

        private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp", ".pdf"];
        private const long MaxFileSize = 5 * 1024 * 1024; 

        public UploadController(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpPost]
        public async Task<IActionResult> Upload(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file provided.");

            if (file.Length > MaxFileSize)
                return BadRequest("File size must not exceed 5MB.");

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(ext))
                return BadRequest("Only .jpg, .jpeg, .png and .webp files are allowed.");

            if (!await IsValidFileContentAsync(file))
                return BadRequest("File content does not match a supported format.");

            var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var url = $"{Request.Scheme}://{Request.Host}/api/upload/{fileName}";
            return Ok(new { url });
        }

        [HttpGet("{fileName}")]
        [AllowAnonymous]
        public IActionResult Download(string fileName)
        {
            
            var sanitized = Path.GetFileName(fileName);
            if (string.IsNullOrEmpty(sanitized))
                return BadRequest();

            var path = Path.Combine(_env.WebRootPath, "uploads", sanitized);
            if (!System.IO.File.Exists(path))
                return NotFound();

            var ext = Path.GetExtension(sanitized).ToLowerInvariant();
            var contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".pdf" => "application/pdf",
                _ => "application/octet-stream"
            };

            return PhysicalFile(path, contentType);
        }

        private static async Task<bool> IsValidFileContentAsync(IFormFile file)
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

            
            if (header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46)
                return true;

            return false;
        }
    }
}
