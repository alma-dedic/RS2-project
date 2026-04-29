import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/model/responses/user_profile.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class UserProfileProvider extends BaseProvider<UserProfile> {
  UserProfileProvider() : super('userprofile');

  @override
  UserProfile fromJson(data) => UserProfile.fromJson(data);

  Future<UserProfile?> getMe() async {
    final res = await http.get(
      Uri.parse('${BaseProvider.baseUrl}userprofile/me'),
      headers: createHeaders(),
    );
    if (res.statusCode == 404) return null;
    isValidResponse(res);
    return UserProfile.fromJson(jsonDecode(res.body));
  }
}
