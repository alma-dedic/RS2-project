import 'package:heartforcharity_shared/model/responses/address.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class AddressProvider extends BaseProvider<Address> {
  AddressProvider() : super('address');

  @override
  Address fromJson(data) => Address.fromJson(data);
}
