class City {
  final int cityId;
  final String name;
  final int countryId;
  final String countryName;

  City({
    this.cityId = 0,
    this.name = '',
    this.countryId = 0,
    this.countryName = '',
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        cityId: json['cityId'] ?? 0,
        name: json['name'] ?? '',
        countryId: json['countryId'] ?? 0,
        countryName: json['countryName'] ?? '',
      );
}
