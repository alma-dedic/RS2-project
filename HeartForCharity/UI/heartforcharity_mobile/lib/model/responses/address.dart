class Address {
  final int addressId;
  final String? streetName;
  final String? number;
  final String? postalCode;
  final int cityId;
  final String cityName;
  final String countryName;

  Address({
    this.addressId = 0,
    this.streetName,
    this.number,
    this.postalCode,
    this.cityId = 0,
    this.cityName = '',
    this.countryName = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json['addressId'] ?? 0,
        streetName: json['streetName'],
        number: json['number'],
        postalCode: json['postalCode'],
        cityId: json['cityId'] ?? 0,
        cityName: json['cityName'] ?? '',
        countryName: json['countryName'] ?? '',
      );
}
