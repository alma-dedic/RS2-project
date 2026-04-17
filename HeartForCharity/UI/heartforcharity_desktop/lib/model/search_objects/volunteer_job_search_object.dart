import 'package:heartforcharity_desktop/model/search_objects/base_search_object.dart';

class VolunteerJobSearchObject extends BaseSearchObject {
  final int? categoryId;
  final String? status;
  final int? organisationProfileId;
  final bool? isRemote;
  final int? cityId;

  VolunteerJobSearchObject({
    super.fts,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.retrieveAll,
    this.categoryId,
    this.status,
    this.organisationProfileId,
    this.isRemote,
    this.cityId,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
        if (organisationProfileId != null)
          'organisationProfileId': organisationProfileId,
        if (isRemote != null) 'isRemote': isRemote,
        if (cityId != null) 'cityId': cityId,
      };
}
