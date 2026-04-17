class CampaignMedia {
  final int campaignMediaId;
  final String? url;
  final String? mediaType;
  final bool isCover;

  CampaignMedia({
    this.campaignMediaId = 0,
    this.url,
    this.mediaType,
    this.isCover = false,
  });

  factory CampaignMedia.fromJson(Map<String, dynamic> json) => CampaignMedia(
        campaignMediaId: json['campaignMediaId'] ?? 0,
        url: json['url'],
        mediaType: json['mediaType'],
        isCover: json['isCover'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'campaignMediaId': campaignMediaId,
        'url': url,
        'mediaType': mediaType,
        'isCover': isCover,
      };
}
