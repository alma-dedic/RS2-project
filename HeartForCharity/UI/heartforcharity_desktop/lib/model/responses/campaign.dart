import 'package:heartforcharity_desktop/model/responses/campaign_media.dart';

class Campaign {
  final int campaignId;
  final int organisationProfileId;
  final String? organisationName;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double targetAmount;
  final double currentAmount;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CampaignMedia> campaignMedias;
  final int donationCount;

  Campaign({
    this.campaignId = 0,
    this.organisationProfileId = 0,
    this.organisationName,
    this.categoryId,
    this.categoryName,
    this.title = '',
    this.description,
    this.startDate,
    this.endDate,
    this.targetAmount = 0,
    this.currentAmount = 0,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.campaignMedias = const [],
    this.donationCount = 0,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        campaignId: json['campaignId'] ?? 0,
        organisationProfileId: json['organisationProfileId'] ?? 0,
        organisationName: json['organisationName'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        title: json['title'] ?? '',
        description: json['description'],
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'])
            : null,
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        campaignMedias: json['campaignMedias'] != null
            ? List<CampaignMedia>.from(
                json['campaignMedias'].map((e) => CampaignMedia.fromJson(e)))
            : [],
        donationCount: json['donationCount'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'organisationProfileId': organisationProfileId,
        'organisationName': organisationName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'title': title,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'campaignMedias': campaignMedias.map((e) => e.toJson()).toList(),

        'donationCount': donationCount,
      };
}
