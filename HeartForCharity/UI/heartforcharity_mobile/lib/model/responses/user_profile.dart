class UserProfile {
  final int userProfileId;
  final int userId;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;
  final int? addressId;
  final String? cityName;
  final String? countryName;
  final DateTime? createdAt;

  UserProfile({
    this.userProfileId = 0,
    this.userId = 0,
    this.firstName = '',
    this.lastName = '',
    this.phoneNumber,
    this.dateOfBirth,
    this.profilePictureUrl,
    this.addressId,
    this.cityName,
    this.countryName,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userProfileId: json['userProfileId'] ?? 0,
        userId: json['userId'] ?? 0,
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        phoneNumber: json['phoneNumber'],
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
        profilePictureUrl: json['profilePictureUrl'],
        addressId: json['addressId'],
        cityName: json['cityName'],
        countryName: json['countryName'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      );
}
