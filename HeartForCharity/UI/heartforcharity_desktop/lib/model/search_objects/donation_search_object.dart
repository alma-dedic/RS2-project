import 'package:heartforcharity_desktop/model/search_objects/base_search_object.dart';

class DonationSearchObject extends BaseSearchObject {
  final int? campaignId;
  final int? userProfileId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status;

  DonationSearchObject({
    super.fts,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.retrieveAll,
    this.campaignId,
    this.userProfileId,
    this.dateFrom,
    this.dateTo,
    this.status,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (campaignId != null) 'campaignId': campaignId,
        if (userProfileId != null) 'userProfileId': userProfileId,
        if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
        if (status != null) 'status': status,
      };
}
