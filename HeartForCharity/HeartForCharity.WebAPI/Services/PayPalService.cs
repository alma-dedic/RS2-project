using Microsoft.Extensions.Configuration;
using PayPalCheckoutSdk.Core;
using PayPalCheckoutSdk.Orders;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HeartForCharity.WebAPI.Services
{
    public interface IPayPalService
    {
        Task<(string OrderId, string ApprovalUrl)> CreateOrderAsync(decimal amount, string currency = "USD");
        Task<(string Status, string? TransactionId)> CaptureOrderAsync(string orderId);
    }

    public class PayPalService : IPayPalService
    {
        private readonly PayPalHttpClient _client;

        public PayPalService(IConfiguration configuration)
        {
            var clientId = configuration["PayPal:ClientId"]!;
            var secret   = configuration["PayPal:Secret"]!;
            var mode     = configuration["PayPal:Mode"] ?? "sandbox";

            PayPalEnvironment environment = mode == "live"
                ? new LiveEnvironment(clientId, secret)
                : new SandboxEnvironment(clientId, secret);

            _client = new PayPalHttpClient(environment);
        }

        public async Task<(string OrderId, string ApprovalUrl)> CreateOrderAsync(decimal amount, string currency = "USD")
        {
            var request = new OrdersCreateRequest();
            request.Prefer("return=representation");
            request.RequestBody(new OrderRequest
            {
                CheckoutPaymentIntent = "CAPTURE",
                PurchaseUnits = new List<PurchaseUnitRequest>
                {
                    new PurchaseUnitRequest
                    {
                        AmountWithBreakdown = new AmountWithBreakdown
                        {
                            CurrencyCode = currency,
                            Value        = amount.ToString("F2")
                        }
                    }
                },
                ApplicationContext = new ApplicationContext
                {
                    ReturnUrl         = "https://example.com/payment/return",
                    CancelUrl         = "https://example.com/payment/cancel",
                    ShippingPreference = "NO_SHIPPING",
                    UserAction        = "PAY_NOW"
                }
            });

            var response = await _client.Execute(request);
            var order    = response.Result<Order>();

            string approvalUrl = string.Empty;
            foreach (var link in order.Links)
            {
                if (link.Rel == "approve")
                {
                    approvalUrl = link.Href;
                    break;
                }
            }

            return (order.Id, approvalUrl);
        }

        public async Task<(string Status, string? TransactionId)> CaptureOrderAsync(string orderId)
        {
            var request = new OrdersCaptureRequest(orderId);
            request.RequestBody(new OrderActionRequest());

            var response = await _client.Execute(request);
            var order    = response.Result<Order>();

            string? transactionId = order.PurchaseUnits?[0]?.Payments?.Captures?[0]?.Id;

            return (order.Status, transactionId);
        }
    }
}
