import 'package:heartforcharity_mobile/model/responses/city.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('city');

  @override
  City fromJson(data) => City.fromJson(data);
}
