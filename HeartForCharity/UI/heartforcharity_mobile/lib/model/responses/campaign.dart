class Campaign {
  final int campaignId;
  final int organisationProfileId;
  final String organisationName;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double targetAmount;
  final double currentAmount;
  final String status;
  final DateTime createdAt;
  final int donationCount;

  Campaign({
    required this.campaignId,
    required this.organisationProfileId,
    required this.organisationName,
    this.categoryId,
    this.categoryName,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.createdAt,
    required this.donationCount,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        campaignId: json['campaignId'],
        organisationProfileId: json['organisationProfileId'],
        organisationName: json['organisationName'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        title: json['title'],
        description: json['description'],
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        status: json['status']?.toString() ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        donationCount: (json['donationCount'] as num?)?.toInt() ?? 0,
      );
}
