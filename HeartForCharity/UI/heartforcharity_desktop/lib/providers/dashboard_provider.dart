import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/dashboard_response.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class DashboardProvider extends BaseProvider<DashboardResponse> {
  DashboardProvider() : super('dashboard');

  @override
  DashboardResponse fromJson(data) => DashboardResponse.fromJson(data);

  Future<DashboardResponse> getDashboard() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}dashboard');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    return DashboardResponse.fromJson(jsonDecode(response.body));
  }
}
