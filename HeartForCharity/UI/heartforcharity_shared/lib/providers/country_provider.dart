import 'package:heartforcharity_shared/model/responses/country.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('country');

  @override
  Country fromJson(data) => Country.fromJson(data);
}
