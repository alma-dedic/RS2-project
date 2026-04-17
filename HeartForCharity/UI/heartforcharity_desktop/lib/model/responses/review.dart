class Review {
  final int reviewId;
  final int? volunteerApplicationId;
  final int? organisationProfileId;
  final String? organisationName;
  final int? userProfileId;
  final String? reviewerName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  Review({
    this.reviewId = 0,
    this.volunteerApplicationId,
    this.organisationProfileId,
    this.organisationName,
    this.userProfileId,
    this.reviewerName,
    this.rating = 0,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        reviewId: json['reviewId'] ?? 0,
        volunteerApplicationId: json['volunteerApplicationId'],
        organisationProfileId: json['organisationProfileId'],
        organisationName: json['organisationName'],
        userProfileId: json['userProfileId'],
        reviewerName: json['reviewerName'],
        rating: json['rating'] ?? 0,
        comment: json['comment'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'volunteerApplicationId': volunteerApplicationId,
        'organisationProfileId': organisationProfileId,
        'organisationName': organisationName,
        'userProfileId': userProfileId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt?.toIso8601String(),
      };
}
