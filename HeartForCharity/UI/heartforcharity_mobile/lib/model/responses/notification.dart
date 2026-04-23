class AppNotification {
  final int notificationId;
  final int userProfileId;
  final int? volunteerApplicationId;
  final String title;
  final String message;
  final String type;
  bool isRead;
  final DateTime sentDateTime;

  AppNotification({
    this.notificationId = 0,
    this.userProfileId = 0,
    this.volunteerApplicationId,
    this.title = '',
    this.message = '',
    this.type = 'General',
    this.isRead = false,
    DateTime? sentDateTime,
  }) : sentDateTime = sentDateTime ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        notificationId: json['notificationId'] ?? 0,
        userProfileId: json['userProfileId'] ?? 0,
        volunteerApplicationId: json['volunteerApplicationId'],
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'General',
        isRead: json['isRead'] ?? false,
        sentDateTime: json['sentDateTime'] != null
            ? DateTime.parse(json['sentDateTime'])
            : DateTime.now(),
      );
}
