using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HeartForCharity.Services.Migrations
{
    [DbContext(typeof(HeartForCharityDbContext))]
    [Migration("20260420000000_DropVolunteerApplicationUniqueConstraint")]
    public partial class DropVolunteerApplicationUniqueConstraint : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications");

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications",
                columns: new[] { "VolunteerJobId", "UserProfileId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications");

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications",
                columns: new[] { "VolunteerJobId", "UserProfileId" },
                unique: true);
        }
    }
}
