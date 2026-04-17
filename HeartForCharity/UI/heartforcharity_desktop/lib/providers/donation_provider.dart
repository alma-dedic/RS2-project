import 'package:heartforcharity_desktop/model/responses/donation.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class DonationProvider extends BaseProvider<Donation> {
  DonationProvider() : super('donation');

  @override
  Donation fromJson(data) => Donation.fromJson(data);
}
