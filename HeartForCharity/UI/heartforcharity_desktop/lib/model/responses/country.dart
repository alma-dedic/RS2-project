class Country {
  final int countryId;
  final String name;
  final String? isoCode;

  Country({this.countryId = 0, this.name = '', this.isoCode});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        countryId: json['countryId'] ?? 0,
        name: json['name'] ?? '',
        isoCode: json['iSOCode'],
      );
}
