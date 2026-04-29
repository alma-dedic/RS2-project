using HeartForCharity.Model.Responses;
using HeartForCharity.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RecommenderController : ControllerBase
    {
        private readonly IRecommenderService _recommenderService;

        public RecommenderController(IRecommenderService recommenderService)
        {
            _recommenderService = recommenderService;
        }

        [HttpGet("jobs")]
        public async Task<List<RecommendedJobResponse>> GetJobRecommendations()
            => await _recommenderService.GetJobRecommendationsAsync();

        [HttpGet("campaigns")]
        public async Task<List<RecommendedCampaignResponse>> GetCampaignRecommendations()
            => await _recommenderService.GetCampaignRecommendationsAsync();
    }
}
