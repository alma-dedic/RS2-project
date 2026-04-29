import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class OrganisationProfileProvider extends BaseProvider<OrganisationProfile> {
  OrganisationProfileProvider() : super('organisationprofile');

  @override
  OrganisationProfile fromJson(data) => OrganisationProfile.fromJson(data);

  Future<OrganisationProfile> getMe() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}organisationprofile/me');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    return OrganisationProfile.fromJson(jsonDecode(response.body));
  }
}
