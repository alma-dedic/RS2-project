import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class OrganisationProfileProvider extends BaseProvider<OrganisationProfile> {
  OrganisationProfileProvider() : super('organisationprofile');

  @override
  OrganisationProfile fromJson(data) => OrganisationProfile.fromJson(data);
}
