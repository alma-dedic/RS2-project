import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/model/responses/donation.dart';
import 'package:heartforcharity_mobile/model/search_result.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class DonationProvider extends BaseProvider<Donation> {
  DonationProvider() : super('donation');

  @override
  Donation fromJson(data) => Donation.fromJson(data);

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
