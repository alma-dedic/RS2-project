import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  static String? token;
  static String? userType;
  static bool _isRefreshing = false;

  static const _storage = FlutterSecureStorage(
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static String baseUrl = const String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://localhost:5145/api/',
  );

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initializeFromStorage() async {
    token = await _storage.read(key: 'access_token');
    userType = await _storage.read(key: 'user_type');
    if (token != null) {
      _isLoggedIn = true;
    }
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['accessToken'];
      userType = data['user']['userType'];

      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      await _storage.write(key: 'user_type', value: userType);

      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    if (response.statusCode == 429) {
      throw Exception('rate_limit');
    }

    return false;
  }

  // Called automatically by BaseProvider when a 401 is received
  static Future<bool> tryRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final storedRefreshToken = await _storage.read(key: 'refresh_token');
      if (storedRefreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${baseUrl}user/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': storedRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['accessToken'];
        userType = data['user']['userType'];

        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        await _storage.write(key: 'user_type', value: userType);

        return true;
      }

      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken != null) {
      await http.post(
        Uri.parse('${baseUrl}user/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    }

    token = null;
    userType = null;
    await _storage.deleteAll();
    _isLoggedIn = false;
    notifyListeners();
  }
}
