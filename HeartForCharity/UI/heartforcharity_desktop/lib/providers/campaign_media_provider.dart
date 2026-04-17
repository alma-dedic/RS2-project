import 'package:heartforcharity_desktop/model/responses/campaign_media.dart';
import 'package:heartforcharity_desktop/providers/base_provider.dart';

class CampaignMediaProvider extends BaseProvider<CampaignMedia> {
  CampaignMediaProvider() : super('campaignmedia');

  @override
  CampaignMedia fromJson(data) => CampaignMedia.fromJson(data);
}
