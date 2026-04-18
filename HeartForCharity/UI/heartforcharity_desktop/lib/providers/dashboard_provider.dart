import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/dashboard_response.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class DashboardProvider {
  Future<DashboardResponse> getDashboard() async {
    var uri = Uri.parse('${BaseProvider.baseUrl}dashboard');
    var response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${AuthProvider.token}',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await http.get(uri, headers: {
          'Authorization': 'Bearer ${AuthProvider.token}',
          'Content-Type': 'application/json',
        });
      }
    }

    if (response.statusCode == 200) {
      return DashboardResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load dashboard data.');
  }
}
