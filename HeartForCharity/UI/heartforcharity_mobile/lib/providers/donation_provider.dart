import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/model/responses/donation.dart';
import 'package:heartforcharity_shared/model/search_result.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class DonationProvider extends BaseProvider<Donation> {
  DonationProvider() : super('donation');

  @override
  Donation fromJson(data) => Donation.fromJson(data);

  Future<Map<String, dynamic>> createOrder({
    required int campaignId,
    required double amount,
    required bool isAnonymous,
  }) async {
    final url = '${BaseProvider.baseUrl}donation/create-order';
    final res = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode({
        'campaignId': campaignId,
        'amount': amount,
        'isAnonymous': isAnonymous,
      }),
    );
    isValidResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Donation> captureOrder(String orderId) async {
    final url = '${BaseProvider.baseUrl}donation/capture/$orderId';
    final res = await http.post(Uri.parse(url), headers: createHeaders());
    isValidResponse(res);
    return fromJson(jsonDecode(res.body));
  }

  Future<SearchResult<Donation>> getCampaignDonations(int campaignId) async {
    final url = '${BaseProvider.baseUrl}donation/campaign/$campaignId';
    final res = await http.get(Uri.parse(url), headers: createHeaders());
    isValidResponse(res);
    final data = jsonDecode(res.body);
    final result = SearchResult<Donation>();
    result.totalCount = data['totalCount'] ?? 0;
    result.items = List<Donation>.from(
      (data['items'] as List).map((e) => fromJson(e)),
    );
    return result;
  }

  Future<SearchResult<Donation>> getUserDonations({Map? filter}) async {
    var url = '${BaseProvider.baseUrl}donation/user';
    if (filter != null) {
      final queryString = getQueryString(filter);
      url = '$url?$queryString';
    }
    final res = await http.get(Uri.parse(url), headers: createHeaders());
    isValidResponse(res);
    final data = jsonDecode(res.body);
    final result = SearchResult<Donation>();
    result.totalCount = data['totalCount'] ?? 0;
    result.items = List<Donation>.from(
      (data['items'] as List).map((e) => fromJson(e)),
    );
    return result;
  }
}
