using HeartForCharity.Model.Requests;
using HeartForCharity.Model.Responses;
using HeartForCharity.Model.SearchObjects;
using HeartForCharity.Services;
using HeartForCharity.WebAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HeartForCharity.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DonationController : BaseCRUDController<DonationResponse, DonationSearchObject, DonationInsertRequest, DonationInsertRequest>
    {
        private readonly IDonationService _donationService;
        private readonly IPayPalService _payPalService;

        public DonationController(IDonationService service, IPayPalService payPalService) : base(service)
        {
            _donationService = service;
            _payPalService   = payPalService;
        }

        [Authorize(Roles = "Organisation,Admin")]
        [HttpGet("")]
        public override async Task<HeartForCharity.Model.Responses.PagedResult<DonationResponse>> Get([FromQuery] DonationSearchObject? search = null)
            => await base.Get(search);

        [Authorize(Roles = "User")]
        [HttpGet("user")]
        public async Task<HeartForCharity.Model.Responses.PagedResult<DonationResponse>> GetUser([FromQuery] DonationSearchObject? search = null)
            => await _donationService.GetMyAsync(search ?? new DonationSearchObject());

        [Authorize(Roles = "User,Organisation,Admin")]
        [HttpGet("{id}")]
        public override async Task<DonationResponse?> GetById(int id)
            => await base.GetById(id);

        [Authorize(Roles = "User")]
        [HttpPost("create-order")]
        public async Task<DonationCreateOrderResponse> CreateOrder([FromBody] DonationCreateOrderRequest request)
        {
            var (orderId, approvalUrl) = await _payPalService.CreateOrderAsync(request.Amount);
            return await _donationService.CreateOrderAsync(request, orderId, approvalUrl);
        }

        [Authorize(Roles = "User")]
        [HttpPost("capture/{orderId}")]
        public async Task<DonationResponse> Capture(string orderId)
        {
            var (status, transactionId) = await _payPalService.CaptureOrderAsync(orderId);
            return await _donationService.CaptureAsync(orderId, status ?? "FAILED", transactionId);
        }

        [Authorize(Roles = "User")]
        [HttpPost]
        public override async Task<DonationResponse> Create([FromBody] DonationInsertRequest request)
            => await base.Create(request);

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public override async Task<DonationResponse?> Update(int id, [FromBody] DonationInsertRequest request)
            => await base.Update(id, request);

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
            => await base.Delete(id);
    }
}
