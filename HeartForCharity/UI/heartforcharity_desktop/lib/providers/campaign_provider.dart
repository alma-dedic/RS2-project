import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/model/search_result.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class CampaignProvider extends BaseProvider<Campaign> {
  CampaignProvider() : super('campaign');

  @override
  Campaign fromJson(data) => Campaign.fromJson(data);

  Future<SearchResult<Campaign>> getMy({dynamic filter}) async {
    var url = '${BaseProvider.baseUrl}campaign/my';
    if (filter != null) {
      url = '$url?${getQueryString(filter)}';
    }

    var uri = Uri.parse(url);
    var response = await http.get(uri, headers: createHeaders());

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await http.get(uri, headers: createHeaders());
      }
    }

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      var result = SearchResult<Campaign>();
      result.totalCount = data['totalCount'];
      result.items = List<Campaign>.from(data['items'].map((e) => fromJson(e)));
      return result;
    }
    throw Exception('Unknown error');
  }

  Future<Campaign?> complete(int id) async {
    var url = '${BaseProvider.baseUrl}campaign/$id/complete';
    var uri = Uri.parse(url);
    var response = await http.patch(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      return Campaign.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Campaign?> cancel(int id) async {
    var url = '${BaseProvider.baseUrl}campaign/$id/cancel';
    var uri = Uri.parse(url);
    var response = await http.patch(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      return Campaign.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
