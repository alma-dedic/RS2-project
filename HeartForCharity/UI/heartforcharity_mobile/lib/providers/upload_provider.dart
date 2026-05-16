import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class UploadProvider with ChangeNotifier {
  Future<String> uploadImage(String filePath) =>
      _upload(filePath, 'image', 'image', _imageMediaType(filePath));
  Future<String> uploadDocument(String filePath) =>
      _upload(filePath, 'document', 'document', _documentMediaType(filePath));

  Future<String> _upload(
    String filePath,
    String endpoint,
    String label,
    MediaType? contentType,
  ) async {
    final url = Uri.parse('${BaseProvider.baseUrl}upload/$endpoint');

    var response = await _send(url, filePath, contentType);

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await _send(url, filePath, contentType);
      }
    }

    if (response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    }

    String message = 'Failed to upload $label (${response.statusCode}).';
    if (response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        if (body is String && body.isNotEmpty) message = body;
      } catch (_) {
        if (response.body.length < 300) message = response.body;
      }
    }
    throw Exception(message);
  }

  Future<http.Response> _send(Uri url, String filePath, MediaType? contentType) async {
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: contentType,
    ));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  MediaType? _imageMediaType(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return null;
  }

  MediaType? _documentMediaType(String filePath) {
    if (filePath.toLowerCase().endsWith('.pdf')) return MediaType('application', 'pdf');
    return null;
  }
}
