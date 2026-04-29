class RecommendedCampaign {
  final int campaignId;
  final String title;
  final String organisationName;
  final String? categoryName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? endDate;
  final double score;
  final List<String> reasons;

  RecommendedCampaign({
    required this.campaignId,
    required this.title,
    required this.organisationName,
    this.categoryName,
    required this.targetAmount,
    required this.currentAmount,
    this.endDate,
    required this.score,
    required this.reasons,
  });

  factory RecommendedCampaign.fromJson(Map<String, dynamic> json) => RecommendedCampaign(
        campaignId: json['campaignId'] as int,
        title: json['title'] as String,
        organisationName: json['organisationName'] as String,
        categoryName: json['categoryName'] as String?,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        score: (json['score'] as num).toDouble(),
        reasons: List<String>.from(json['reasons'] as List? ?? []),
      );
}
