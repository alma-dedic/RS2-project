using System;
using HeartForCharity.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HeartForCharity.Services.Migrations
{
    [DbContext(typeof(HeartForCharityDbContext))]
    [Migration("20260420000001_AddApplicationAuditFields")]
    public partial class AddApplicationAuditFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ReviewedByUserId",
                table: "VolunteerApplications",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedAt",
                table: "VolunteerApplications",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerApplications_ReviewedByUserId",
                table: "VolunteerApplications",
                column: "ReviewedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications",
                column: "ReviewedByUserId",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_VolunteerApplications_Users_ReviewedByUserId",
                table: "VolunteerApplications");

            migrationBuilder.DropIndex(
                name: "IX_VolunteerApplications_ReviewedByUserId",
                table: "VolunteerApplications");

            migrationBuilder.DropColumn(
                name: "ReviewedByUserId",
                table: "VolunteerApplications");

            migrationBuilder.DropColumn(
                name: "ReviewedAt",
                table: "VolunteerApplications");
        }
    }
}
