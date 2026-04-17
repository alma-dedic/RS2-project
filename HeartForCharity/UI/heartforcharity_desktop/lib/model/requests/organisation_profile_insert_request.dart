class OrganisationProfileInsertRequest {
  final String name;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final int? addressId;
  final String? logoUrl;
  final int? organisationTypeId;

  OrganisationProfileInsertRequest({
    required this.name,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.addressId,
    this.logoUrl,
    this.organisationTypeId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'addressId': addressId,
        'logoUrl': logoUrl,
        'organisationTypeId': organisationTypeId,
      };
}
