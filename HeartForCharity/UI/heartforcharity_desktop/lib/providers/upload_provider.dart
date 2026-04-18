import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class UploadProvider with ChangeNotifier {
  Future<String> uploadImage(String filePath) async {
    final url = Uri.parse('${BaseProvider.baseUrl}upload');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      throw Exception('Failed to upload image.');
    }
  }
}
