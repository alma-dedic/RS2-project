import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/volunteer_job.dart';
import 'package:heartforcharity_desktop/model/search_result.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class VolunteerJobProvider extends BaseProvider<VolunteerJob> {
  VolunteerJobProvider() : super('volunteerjob');

  @override
  VolunteerJob fromJson(data) => VolunteerJob.fromJson(data);

  Future<SearchResult<VolunteerJob>> getMy({dynamic filter}) async {
    var url = '${BaseProvider.baseUrl}volunteerjob/my';
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
      var result = SearchResult<VolunteerJob>();
      result.totalCount = data['totalCount'];
      result.items =
          List<VolunteerJob>.from(data['items'].map((e) => fromJson(e)));
      return result;
    }
    throw Exception('Unknown error');
  }

  Future<VolunteerJob?> complete(int id) async {
    var url = '${BaseProvider.baseUrl}volunteerjob/$id/complete';
    var uri = Uri.parse(url);
    var response = await http.patch(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      return VolunteerJob.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<VolunteerJob?> cancel(int id) async {
    var url = '${BaseProvider.baseUrl}volunteerjob/$id/cancel';
    var uri = Uri.parse(url);
    var response = await http.patch(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      return VolunteerJob.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
