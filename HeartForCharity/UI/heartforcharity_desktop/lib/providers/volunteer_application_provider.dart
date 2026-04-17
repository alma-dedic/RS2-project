import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/volunteer_application.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class VolunteerApplicationProvider extends BaseProvider<VolunteerApplication> {
  VolunteerApplicationProvider() : super('volunteerapplication');

  @override
  VolunteerApplication fromJson(data) => VolunteerApplication.fromJson(data);

  Future<VolunteerApplication?> approve(int id) async {
    var url = '${BaseProvider.baseUrl}volunteerapplication/$id/approve';
    var uri = Uri.parse(url);
    var response = await http.patch(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      return VolunteerApplication.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<VolunteerApplication?> reject(int id, {String? reason}) async {
    var url = '${BaseProvider.baseUrl}volunteerapplication/$id/reject';
    var uri = Uri.parse(url);
    var response = await http.patch(
      uri,
      headers: createHeaders(),
      body: reason != null ? jsonEncode({'rejectionReason': reason}) : null,
    );

    if (isValidResponse(response)) {
      return VolunteerApplication.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
