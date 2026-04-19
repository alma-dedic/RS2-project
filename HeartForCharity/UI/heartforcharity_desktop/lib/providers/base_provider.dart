import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:heartforcharity_desktop/model/search_result.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String baseUrl = const String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://localhost:5145/api/',
  );

  String _endpoint = '';

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
  }

  // Executes a request and retries once after token refresh on 401
  Future<Response> _execute(Future<Response> Function() request) async {
    var response = await request();

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await request();
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

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      var result = SearchResult<T>();
      result.totalCount = data['totalCount'];
      result.items = List<T>.from(data['items'].map((e) => fromJson(e)));
      return result;
    } else {
      throw Exception('Unknown error');
    }
  }

  Future<T> getById(int id) async {
    var url = '$baseUrl$_endpoint/$id';
    var uri = Uri.parse(url);
    var response = await _execute(() => http.get(uri, headers: createHeaders()));

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception('Unknown error');
    }
  }

  Future<T> insert(dynamic request) async {
    var url = '$baseUrl$_endpoint';
    var uri = Uri.parse(url);
    var response = await _execute(
      () => http.post(uri, headers: createHeaders(), body: jsonEncode(request)),
    );

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception('Unknown error');
    }
  }

  Future<T> update(int id, dynamic request) async {
    var url = '$baseUrl$_endpoint/$id';
    var uri = Uri.parse(url);
    var response = await _execute(
      () => http.put(uri, headers: createHeaders(), body: jsonEncode(request)),
    );

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception('Unknown error');
    }
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
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Something went wrong. Please try again.');
    }
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
