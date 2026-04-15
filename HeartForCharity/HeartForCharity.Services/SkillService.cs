using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services.Database;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public class SkillService : BaseCRUDService<SkillResponse, SkillSearchObject, Skill, SkillUpsertRequest, SkillUpsertRequest>, ISkillService
    {
        public SkillService(HeartForCharityDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Skill> ApplyFilter(IQueryable<Skill> query, SkillSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(s => s.Name.Contains(search.FTS));
            return query;
        }
    }
}
