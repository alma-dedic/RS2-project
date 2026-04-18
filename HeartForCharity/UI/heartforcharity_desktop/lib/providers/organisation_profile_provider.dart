import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class OrganisationProfileProvider extends BaseProvider<OrganisationProfile> {
  OrganisationProfileProvider() : super('organisationprofile');

  @override
  OrganisationProfile fromJson(data) => OrganisationProfile.fromJson(data);

  Future<OrganisationProfile> getMe() async {
    var uri = Uri.parse('${BaseProvider.baseUrl}organisationprofile/me');
    var response = await http.get(uri, headers: createHeaders());

    if (response.statusCode == 401) {
      final refreshed = await AuthProvider.tryRefresh();
      if (refreshed) response = await http.get(uri, headers: createHeaders());
    }

    if (isValidResponse(response)) {
      return OrganisationProfile.fromJson(jsonDecode(response.body));
    }
    throw Exception('Unknown error');
  }
}
