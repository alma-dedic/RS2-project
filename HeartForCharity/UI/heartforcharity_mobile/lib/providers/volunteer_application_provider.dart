import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/model/responses/volunteer_application.dart';
import 'package:heartforcharity_shared/model/search_result.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class VolunteerApplicationProvider extends BaseProvider<VolunteerApplication> {
  VolunteerApplicationProvider() : super('volunteerapplication');

  @override
  VolunteerApplication fromJson(data) => VolunteerApplication.fromJson(data);

  Future<SearchResult<VolunteerApplication>> getUserApplications({Map? filter}) async {
    var url = '${BaseProvider.baseUrl}volunteerapplication/user';
    if (filter != null) {
      final queryString = getQueryString(filter);
      url = '$url?$queryString';
    }
    final res = await http.get(Uri.parse(url), headers: createHeaders());
    isValidResponse(res);
    final data = jsonDecode(res.body);
    final result = SearchResult<VolunteerApplication>();
    result.totalCount = data['totalCount'] ?? 0;
    result.items = List<VolunteerApplication>.from(
      (data['items'] as List).map((e) => fromJson(e)),
    );
    return result;
  }

  Future<void> withdraw(int id) async {
    final res = await http.patch(
      Uri.parse('${BaseProvider.baseUrl}volunteerapplication/$id/withdraw'),
      headers: createHeaders(),
    );
    isValidResponse(res);
  }
}
