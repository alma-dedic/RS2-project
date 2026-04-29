import 'package:heartforcharity_mobile/model/responses/organisation_profile.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class OrganisationProfileProvider extends BaseProvider<OrganisationProfile> {
  OrganisationProfileProvider() : super('organisationprofile');

  @override
  OrganisationProfile fromJson(data) => OrganisationProfile.fromJson(data);
}
