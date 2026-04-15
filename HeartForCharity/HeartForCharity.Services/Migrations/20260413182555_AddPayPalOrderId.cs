using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HeartForCharity.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPayPalOrderId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PayPalOrderId",
                table: "Donations",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PayPalOrderId",
                table: "Donations");
        }
    }
}
