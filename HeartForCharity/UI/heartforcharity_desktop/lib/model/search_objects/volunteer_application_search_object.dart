import 'package:heartforcharity_desktop/model/search_objects/base_search_object.dart';

class VolunteerApplicationSearchObject extends BaseSearchObject {
  final int? volunteerJobId;
  final int? userProfileId;
  final String? status;
  final bool? isCompleted;

  VolunteerApplicationSearchObject({
    super.fts,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.retrieveAll,
    this.volunteerJobId,
    this.userProfileId,
    this.status,
    this.isCompleted,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (volunteerJobId != null) 'volunteerJobId': volunteerJobId,
        if (userProfileId != null) 'userProfileId': userProfileId,
        if (status != null) 'status': status,
        if (isCompleted != null) 'isCompleted': isCompleted,
      };
}
