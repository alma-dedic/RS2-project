import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:heartforcharity_mobile/main.dart';
import 'package:heartforcharity_mobile/model/search_result.dart';
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_mobile/screens/login_screen.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String baseUrl = const String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://10.102.222.159:5145/api/',
  );

  String _endpoint = '';

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
  }

  Future<Response> _execute(Future<Response> Function() request) async {
    var response = await request();

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await request();
      } else {
        await AuthProvider.clearSession();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        throw Exception('Session expired. Please log in again.');
      }
    }

    return response;
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = '$baseUrl$_endpoint';

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = '$url?$queryString';
    }

    var uri = Uri.parse(url);
    var response = await _execute(() => http.get(uri, headers: createHeaders()));

    isValidResponse(response);
    var data = jsonDecode(response.body);
    var result = SearchResult<T>();
    result.totalCount = data['totalCount'];
    result.items = List<T>.from(data['items'].map((e) => fromJson(e)));
    return result;
  }

  Future<T> getById(int id) async {
    var url = '$baseUrl$_endpoint/$id';
    var uri = Uri.parse(url);
    var response = await _execute(() => http.get(uri, headers: createHeaders()));

    isValidResponse(response);
    var data = jsonDecode(response.body);
    return fromJson(data);
  }

  Future<T> insert(dynamic request) async {
    var url = '$baseUrl$_endpoint';
    var uri = Uri.parse(url);
    var response = await _execute(
      () => http.post(uri, headers: createHeaders(), body: jsonEncode(request)),
    );

    isValidResponse(response);
    var data = jsonDecode(response.body);
    return fromJson(data);
  }

  Future<T> update(int id, dynamic request) async {
    var url = '$baseUrl$_endpoint/$id';
    var uri = Uri.parse(url);
    var response = await _execute(
      () => http.put(uri, headers: createHeaders(), body: jsonEncode(request)),
    );

    isValidResponse(response);
    var data = jsonDecode(response.body);
    return fromJson(data);
  }

  Future<bool> delete(int id) async {
    var url = '$baseUrl$_endpoint/$id';
    var uri = Uri.parse(url);
    var response = await _execute(() => http.delete(uri, headers: createHeaders()));

    return isValidResponse(response);
  }

  T fromJson(dynamic data) {
    throw Exception('Method not implemented');
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) return true;
    throw Exception(_extractErrorMessage(response));
  }

  String _extractErrorMessage(Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          if (first is String) return first;
        }
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;
        final title = body['title'];
        if (title is String && title.isNotEmpty) return title;
      }
    } catch (_) {}
    return 'Request failed (HTTP ${response.statusCode}).';
  }

  Map<String, String> createHeaders() {
    var headers = {'Content-Type': 'application/json'};
    if (AuthProvider.token != null) {
      headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    }
    return headers;
  }

  String getQueryString(Map params,
      {String prefix = '&', bool inRecursion = false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }
}
