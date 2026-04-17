class CampaignMediaUpsertRequest {
  final int campaignId;
  final String url;
  final String mediaType;
  final bool isCover;

  CampaignMediaUpsertRequest({
    required this.campaignId,
    required this.url,
    this.mediaType = 'Image',
    this.isCover = false,
  });

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'url': url,
        'mediaType': mediaType,
        'isCover': isCover,
      };
}
