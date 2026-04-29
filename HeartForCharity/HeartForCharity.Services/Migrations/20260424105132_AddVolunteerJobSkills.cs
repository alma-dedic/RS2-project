using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HeartForCharity.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddVolunteerJobSkills : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications");

            migrationBuilder.DropIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications");

            migrationBuilder.DropColumn(
                name: "Requirements",
                table: "VolunteerJobs");

            migrationBuilder.CreateTable(
                name: "VolunteerJobSkills",
                columns: table => new
                {
                    VolunteerJobSkillId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VolunteerJobId = table.Column<int>(type: "int", nullable: false),
                    SkillId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VolunteerJobSkills", x => x.VolunteerJobSkillId);
                    table.ForeignKey(
                        name: "FK_VolunteerJobSkills_Skills_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skills",
                        principalColumn: "SkillId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VolunteerJobSkills_VolunteerJobs_VolunteerJobId",
                        column: x => x.VolunteerJobId,
                        principalTable: "VolunteerJobs",
                        principalColumn: "VolunteerJobId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications",
                columns: new[] { "VolunteerJobId", "UserProfileId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerJobSkills_SkillId",
                table: "VolunteerJobSkills",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerJobSkills_VolunteerJobId_SkillId",
                table: "VolunteerJobSkills",
                columns: new[] { "VolunteerJobId", "SkillId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications",
                column: "ReviewedByUserId",
                principalTable: "Users",
                principalColumn: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications");

            migrationBuilder.DropTable(
                name: "VolunteerJobSkills");

            migrationBuilder.DropIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications");

            migrationBuilder.AddColumn<string>(
                name: "Requirements",
                table: "VolunteerJobs",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerApplications_VolunteerJobId_UserProfileId",
                table: "VolunteerApplications",
                columns: new[] { "VolunteerJobId", "UserProfileId" });

            migrationBuilder.AddForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications",
                column: "ReviewedByUserId",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
