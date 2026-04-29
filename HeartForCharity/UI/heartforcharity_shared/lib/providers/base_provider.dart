import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:heartforcharity_shared/model/search_result.dart';
import 'package:heartforcharity_shared/providers/session_handler.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5145/api/',
  );

  /// Set by each app at startup before any provider is used.
  static SessionHandler? sessionHandler;

  static const _sessionExpiredMessage = 'Session expired. Please log in again.';
  static bool _isHandlingExpiration = false;

  /// Returns true if the given exception represents a session-expired redirect.
  /// Use in catch blocks to skip showing a per-call SnackBar in that case
  /// (the user is already being redirected to the login screen).
  static bool isSessionExpired(Object e) =>
      e.toString().contains(_sessionExpiredMessage);

  /// Strips the leading "Exception: " prefix from an error so the SnackBar
  /// shows just the backend message (e.g. "Title is required" instead of
  /// "Exception: Title is required").
  static String cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  String _endpoint = '';

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
  }

  Future<Response> _execute(Future<Response> Function() request) async {
    var response = await request();

    if (response.statusCode == 401) {
      final handler = sessionHandler;
      final refreshed = handler != null ? await handler.tryRefresh() : false;
      if (refreshed) {
        response = await request();
      } else {
        // Deduplicate: if multiple parallel requests hit 401, only the first
        // one performs the session clear + redirect. The others throw
        // silently so callers can ignore via isSessionExpired().
        if (!_isHandlingExpiration && handler != null) {
          _isHandlingExpiration = true;
          await handler.clearSession();
          handler.redirectToLogin();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _isHandlingExpiration = false;
          });
        }
        throw Exception(_sessionExpiredMessage);
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

  /// Extracts the most specific error message from the backend response body.
  /// Backend returns: { "errors": { "key": ["message", ...] } }
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

  Future<Response> executeHttp(Future<Response> Function() request) => _execute(request);

  Map<String, String> createHeaders() {
    var headers = {'Content-Type': 'application/json'};
    final token = sessionHandler?.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
        query += '$prefix$key=${value.toUtc().toIso8601String()}';
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
