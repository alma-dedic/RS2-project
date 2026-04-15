using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Text;

namespace HeartForCharity.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddHeartForCharityDatabase(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<HeartForCharityDbContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
}
