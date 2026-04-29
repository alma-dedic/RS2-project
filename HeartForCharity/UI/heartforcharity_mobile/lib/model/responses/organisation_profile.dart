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
  final int? addressId;
  final String? cityName;
  final String? countryName;
  final DateTime createdAt;

  OrganisationProfile({
    required this.organisationProfileId,
    required this.userId,
    required this.name,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.organisationTypeId,
    this.organisationTypeName,
    this.addressId,
    this.cityName,
    this.countryName,
    required this.createdAt,
  });

  factory OrganisationProfile.fromJson(Map<String, dynamic> json) =>
      OrganisationProfile(
        organisationProfileId: json['organisationProfileId'],
        userId: json['userId'],
        name: json['name'],
        description: json['description'],
        contactEmail: json['contactEmail'],
        contactPhone: json['contactPhone'],
        logoUrl: json['logoUrl'],
        organisationTypeId: json['organisationTypeId'],
        organisationTypeName: json['organisationTypeName'],
        addressId: json['addressId'],
        cityName: json['cityName'],
        countryName: json['countryName'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
