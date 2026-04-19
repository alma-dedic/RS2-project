class UserResponse {
  final int userId;
  final String username;
  final String email;
  final String userType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserResponse({
    this.userId = 0,
    this.username = '',
    this.email = '',
    this.userType = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        userId: json['userId'] ?? 0,
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        userType: json['userType'] ?? '',
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
