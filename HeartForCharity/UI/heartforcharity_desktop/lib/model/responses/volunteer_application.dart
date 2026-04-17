class VolunteerApplication {
  final int volunteerApplicationId;
  final int volunteerJobId;
  final String? jobTitle;
  final int? userProfileId;
  final String? applicantName;
  final String? coverLetter;
  final String? resumeUrl;
  final String? status;
  final String? rejectionReason;
  final bool isCompleted;
  final DateTime? appliedAt;
  final DateTime? updatedAt;

  VolunteerApplication({
    this.volunteerApplicationId = 0,
    this.volunteerJobId = 0,
    this.jobTitle,
    this.userProfileId,
    this.applicantName,
    this.coverLetter,
    this.resumeUrl,
    this.status,
    this.rejectionReason,
    this.isCompleted = false,
    this.appliedAt,
    this.updatedAt,
  });

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) =>
      VolunteerApplication(
        volunteerApplicationId: json['volunteerApplicationId'] ?? 0,
        volunteerJobId: json['volunteerJobId'] ?? 0,
        jobTitle: json['jobTitle'],
        userProfileId: json['userProfileId'],
        applicantName: json['applicantName'],
        coverLetter: json['coverLetter'],
        resumeUrl: json['resumeUrl'],
        status: json['status'],
        rejectionReason: json['rejectionReason'],
        isCompleted: json['isCompleted'] ?? false,
        appliedAt: json['appliedAt'] != null
            ? DateTime.parse(json['appliedAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'volunteerApplicationId': volunteerApplicationId,
        'volunteerJobId': volunteerJobId,
        'jobTitle': jobTitle,
        'userProfileId': userProfileId,
        'applicantName': applicantName,
        'coverLetter': coverLetter,
        'resumeUrl': resumeUrl,
        'status': status,
        'rejectionReason': rejectionReason,
        'isCompleted': isCompleted,
        'appliedAt': appliedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
