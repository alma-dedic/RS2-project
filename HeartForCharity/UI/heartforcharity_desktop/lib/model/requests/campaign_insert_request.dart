class CampaignInsertRequest {
  final int? categoryId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double targetAmount;

  CampaignInsertRequest({
    this.categoryId,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.targetAmount,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'targetAmount': targetAmount,
      };
}
