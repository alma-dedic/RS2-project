import 'package:heartforcharity_desktop/model/search_objects/base_search_object.dart';

class CampaignSearchObject extends BaseSearchObject {
  final String? title;
  final int? categoryId;
  final String? status;
  final int? organisationProfileId;

  CampaignSearchObject({
    super.fts,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    this.title,
    this.categoryId,
    this.status,
    this.organisationProfileId,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (title != null) 'title': title,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
        if (organisationProfileId != null)
          'organisationProfileId': organisationProfileId,
      };
}
