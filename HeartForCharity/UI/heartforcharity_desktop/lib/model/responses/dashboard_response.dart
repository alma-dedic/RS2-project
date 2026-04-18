class DashboardResponse {
  final int activeCampaigns;
  final int finishedCampaigns;
  final int totalVolunteers;
  final double totalRaised;
  final List<MonthlyDonationItem> monthlyDonations;
  final List<DashboardReviewItem> recentReviews;
  final List<CampaignProgressItem> campaignProgress;

  DashboardResponse({
    required this.activeCampaigns,
    required this.finishedCampaigns,
    required this.totalVolunteers,
    required this.totalRaised,
    required this.monthlyDonations,
    required this.recentReviews,
    required this.campaignProgress,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      activeCampaigns: json['activeCampaigns'] as int,
      finishedCampaigns: json['finishedCampaigns'] as int,
      totalVolunteers: json['totalVolunteers'] as int,
      totalRaised: (json['totalRaised'] as num).toDouble(),
      monthlyDonations: (json['monthlyDonations'] as List)
          .map((e) => MonthlyDonationItem.fromJson(e))
          .toList(),
      recentReviews: (json['recentReviews'] as List)
          .map((e) => DashboardReviewItem.fromJson(e))
          .toList(),
      campaignProgress: (json['campaignProgress'] as List)
          .map((e) => CampaignProgressItem.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyDonationItem {
  final int year;
  final int month;
  final double total;
  final int count;

  MonthlyDonationItem({
    required this.year,
    required this.month,
    required this.total,
    required this.count,
  });

  factory MonthlyDonationItem.fromJson(Map<String, dynamic> json) {
    return MonthlyDonationItem(
      year: json['year'] as int,
      month: json['month'] as int,
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
    );
  }
}

class DashboardReviewItem {
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  DashboardReviewItem({
    required this.reviewerName,
    this.reviewerAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory DashboardReviewItem.fromJson(Map<String, dynamic> json) {
    return DashboardReviewItem(
      reviewerName: json['reviewerName'] as String,
      reviewerAvatarUrl: json['reviewerAvatarUrl'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CampaignProgressItem {
  final int campaignId;
  final String title;
  final double targetAmount;
  final double currentAmount;

  CampaignProgressItem({
    required this.campaignId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory CampaignProgressItem.fromJson(Map<String, dynamic> json) {
    return CampaignProgressItem(
      campaignId: json['campaignId'] as int,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
    );
  }
}
