import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class AccountProvider with ChangeNotifier {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.token}',
      };

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('${BaseProvider.baseUrl}account/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Incorrect current password.');
    }
  }

  Future<void> deleteAccount() async {
    final res = await http.delete(
      Uri.parse('${BaseProvider.baseUrl}account/me'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      try {
        final data = jsonDecode(res.body);
        throw Exception(data['message'] ?? 'Failed to delete account.');
      } catch (_) {
        throw Exception('Failed to delete account.');
      }
    }
  }
}
