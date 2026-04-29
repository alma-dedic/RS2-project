import 'dart:convert';
import 'package:heartforcharity_desktop/model/responses/user_response.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserAdminProvider extends BaseProvider<UserResponse> {
  UserAdminProvider() : super('user');

  @override
  UserResponse fromJson(data) => UserResponse.fromJson(data);

  Future<UserResponse> toggleActive(int userId, UserResponse user) async {
    return update(userId, {
      'username': user.username,
      'email': user.email,
      'userType': user.userType,
      'isActive': !user.isActive,
    });
  }

  Future<void> deleteUser(int userId) async {
    final url = Uri.parse('${BaseProvider.baseUrl}user/$userId');
    final response = await executeHttp(() => http.delete(url, headers: createHeaders()));
    isValidResponse(response);
  }

  Future<UserResponse> updateUserRaw(int userId, Map<String, dynamic> body) async {
    final url = Uri.parse('${BaseProvider.baseUrl}user/$userId');
    final response = await executeHttp(
      () => http.put(url, headers: createHeaders(), body: jsonEncode(body)),
    );
    isValidResponse(response);
    return UserResponse.fromJson(jsonDecode(response.body));
  }
}
