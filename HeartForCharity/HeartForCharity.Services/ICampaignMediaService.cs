using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HeartForCharity.Services
{
    public interface ICampaignMediaService : ICRUDService<CampaignMediaResponse, CampaignMediaSearchObject, CampaignMediaUpsertRequest, CampaignMediaUpsertRequest> { }
}
