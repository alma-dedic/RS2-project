import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class UploadProvider with ChangeNotifier {
  Future<String> uploadImage(String filePath) async {
    final url = Uri.parse('${BaseProvider.baseUrl}upload');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) {
        final retryRequest = http.MultipartRequest('POST', url);
        retryRequest.headers['Authorization'] = 'Bearer ${AuthProvider.token}';
        retryRequest.files.add(await http.MultipartFile.fromPath('file', filePath));
        streamedResponse = await retryRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }

    if (response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    }
    throw Exception('Failed to upload image (${response.statusCode}).');
  }
}
