import 'package:heartforcharity_mobile/model/responses/campaign.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class CampaignProvider extends BaseProvider<Campaign> {
  CampaignProvider() : super('campaign');

  @override
  Campaign fromJson(data) => Campaign.fromJson(data);
}
