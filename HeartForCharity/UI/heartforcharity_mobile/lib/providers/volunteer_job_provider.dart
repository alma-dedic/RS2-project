import 'package:heartforcharity_mobile/model/responses/volunteer_job.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class VolunteerJobProvider extends BaseProvider<VolunteerJob> {
  VolunteerJobProvider() : super('volunteerjob');

  @override
  VolunteerJob fromJson(data) => VolunteerJob.fromJson(data);
}
