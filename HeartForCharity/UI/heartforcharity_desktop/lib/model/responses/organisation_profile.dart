class OrganisationProfile {
  final int organisationProfileId;
  final int userId;
  final String name;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final int? organisationTypeId;
  final String? organisationTypeName;
  final bool isVerified;
  final int? addressId;
  final String? cityName;
  final String? countryName;
  final DateTime? createdAt;

  OrganisationProfile({
    this.organisationProfileId = 0,
    this.userId = 0,
    this.name = '',
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.organisationTypeId,
    this.organisationTypeName,
    this.isVerified = false,
    this.addressId,
    this.cityName,
    this.countryName,
    this.createdAt,
  });

  factory OrganisationProfile.fromJson(Map<String, dynamic> json) =>
      OrganisationProfile(
        organisationProfileId: json['organisationProfileId'] ?? 0,
        userId: json['userId'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        contactEmail: json['contactEmail'],
        contactPhone: json['contactPhone'],
        logoUrl: json['logoUrl'],
        organisationTypeId: json['organisationTypeId'],
        organisationTypeName: json['organisationTypeName'],
        isVerified: json['isVerified'] ?? false,
        addressId: json['addressId'],
        cityName: json['cityName'],
        countryName: json['countryName'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'organisationProfileId': organisationProfileId,
        'userId': userId,
        'name': name,
        'description': description,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'logoUrl': logoUrl,
        'organisationTypeId': organisationTypeId,
        'organisationTypeName': organisationTypeName,
        'isVerified': isVerified,
        'addressId': addressId,
        'cityName': cityName,
        'countryName': countryName,
        'createdAt': createdAt?.toIso8601String(),
      };
}
