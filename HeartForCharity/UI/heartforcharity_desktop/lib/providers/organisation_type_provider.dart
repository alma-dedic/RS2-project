import 'package:heartforcharity_desktop/model/responses/organisation_type.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class OrganisationTypeProvider extends BaseProvider<OrganisationType> {
  OrganisationTypeProvider() : super('organisationtype');

  @override
  OrganisationType fromJson(data) => OrganisationType.fromJson(data);
}
