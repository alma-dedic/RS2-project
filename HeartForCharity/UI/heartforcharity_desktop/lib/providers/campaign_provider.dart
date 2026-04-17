import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class CampaignProvider extends BaseProvider<Campaign> {
  CampaignProvider() : super('campaign');

  @override
  Campaign fromJson(data) => Campaign.fromJson(data);

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
