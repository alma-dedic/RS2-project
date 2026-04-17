import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/volunteer_job.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class VolunteerJobProvider extends BaseProvider<VolunteerJob> {
  VolunteerJobProvider() : super('volunteerjob');

  @override
  VolunteerJob fromJson(data) => VolunteerJob.fromJson(data);

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
