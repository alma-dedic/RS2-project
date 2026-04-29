class RecommendedJob {
  final int volunteerJobId;
  final String title;
  final String organisationName;
  final String? categoryName;
  final DateTime? startDate;
  final bool isRemote;
  final String? cityName;
  final int positionsRemaining;
  final double score;
  final List<String> reasons;

  RecommendedJob({
    required this.volunteerJobId,
    required this.title,
    required this.organisationName,
    this.categoryName,
    this.startDate,
    required this.isRemote,
    this.cityName,
    required this.positionsRemaining,
    required this.score,
    required this.reasons,
  });

  factory RecommendedJob.fromJson(Map<String, dynamic> json) => RecommendedJob(
        volunteerJobId: json['volunteerJobId'] as int,
        title: json['title'] as String,
        organisationName: json['organisationName'] as String,
        categoryName: json['categoryName'] as String?,
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
        isRemote: json['isRemote'] as bool? ?? false,
        cityName: json['cityName'] as String?,
        positionsRemaining: (json['positionsRemaining'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num).toDouble(),
        reasons: List<String>.from(json['reasons'] as List? ?? []),
      );
}
