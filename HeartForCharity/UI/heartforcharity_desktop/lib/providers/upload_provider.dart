import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class UploadProvider with ChangeNotifier {
  Future<String> uploadImage(String filePath) async {
    final url = Uri.parse('${BaseProvider.baseUrl}upload/image');
    final contentType = _imageMediaType(filePath);

    var response = await _sendUpload(url, filePath, contentType);

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        response = await _sendUpload(url, filePath, contentType);
      }
    }

    if (response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      String message = 'Failed to upload image. (${response.statusCode})';
      try {
        final body = response.body;
        if (body.isNotEmpty) message = '$message: $body';
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<http.Response> _sendUpload(Uri url, String filePath, MediaType? contentType) async {
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
}
