using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HeartForCharity.Services.Migrations
{
    /// <inheritdoc />
    public partial class AllowReapplyAfterWithdraw : Migration
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
                columns: new[] { "VolunteerJobId", "UserProfileId" },
                unique: true,
                filter: "[Status] <> 3");
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
