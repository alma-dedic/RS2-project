import 'package:heartforcharity_mobile/model/responses/country.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('country');

  @override
  Country fromJson(data) => Country.fromJson(data);
}
