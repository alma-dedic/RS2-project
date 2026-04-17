import 'package:heartforcharity_desktop/model/search_objects/base_search_object.dart';

class ReviewSearchObject extends BaseSearchObject {
  final int? organisationProfileId;
  final int? userProfileId;
  final int? minRating;
  final int? maxRating;

  ReviewSearchObject({
    super.fts,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.retrieveAll,
    this.organisationProfileId,
    this.userProfileId,
    this.minRating,
    this.maxRating,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (organisationProfileId != null)
          'organisationProfileId': organisationProfileId,
        if (userProfileId != null) 'userProfileId': userProfileId,
        if (minRating != null) 'minRating': minRating,
        if (maxRating != null) 'maxRating': maxRating,
      };
}
