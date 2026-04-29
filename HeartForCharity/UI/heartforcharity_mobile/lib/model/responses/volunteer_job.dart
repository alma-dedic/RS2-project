import 'package:heartforcharity_mobile/model/responses/skill.dart';

class VolunteerJob {
  final int volunteerJobId;
  final int organisationProfileId;
  final String organisationName;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final List<Skill> requiredSkills;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRemote;
  final int positionsAvailable;
  final int positionsFilled;
  final int positionsRemaining;
  final String status;
  final int? addressId;
  final String? cityName;
  final DateTime createdAt;

  VolunteerJob({
    required this.volunteerJobId,
    required this.organisationProfileId,
    required this.organisationName,
    this.categoryId,
    this.categoryName,
    required this.title,
    this.description,
    this.requiredSkills = const [],
    this.startDate,
    this.endDate,
    required this.isRemote,
    required this.positionsAvailable,
    required this.positionsFilled,
    required this.positionsRemaining,
    required this.status,
    this.addressId,
    this.cityName,
    required this.createdAt,
  });

  factory VolunteerJob.fromJson(Map<String, dynamic> json) {
    final available = (json['positionsAvailable'] as num?)?.toInt() ?? 0;
    final filled = (json['positionsFilled'] as num?)?.toInt() ?? 0;
    return VolunteerJob(
      volunteerJobId: json['volunteerJobId'],
      organisationProfileId: json['organisationProfileId'],
      organisationName: json['organisationName'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      title: json['title'],
      description: json['description'],
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
              ?.map((s) => Skill.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isRemote: json['isRemote'] ?? false,
      positionsAvailable: available,
      positionsFilled: filled,
      positionsRemaining: (json['positionsRemaining'] as num?)?.toInt() ?? (available - filled),
      status: json['status']?.toString() ?? '',
      addressId: json['addressId'],
      cityName: json['cityName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
