class OrganisationType {
  final int organisationTypeId;
  final String name;
  final String? description;

  OrganisationType({this.organisationTypeId = 0, this.name = '', this.description});

  factory OrganisationType.fromJson(Map<String, dynamic> json) => OrganisationType(
        organisationTypeId: json['organisationTypeId'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
      );
}
