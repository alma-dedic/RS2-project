class CampaignUpdateRequest {
  final int? categoryId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double targetAmount;
  final String? status;

  CampaignUpdateRequest({
    this.categoryId,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.targetAmount,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'targetAmount': targetAmount,
        'status': status,
      };
}
