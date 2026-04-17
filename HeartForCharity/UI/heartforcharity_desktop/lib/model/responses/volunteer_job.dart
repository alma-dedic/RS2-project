class VolunteerJob {
  final int volunteerJobId;
  final int organisationProfileId;
  final String? organisationName;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final String? requirements;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRemote;
  final int positionsAvailable;
  final int positionsFilled;
  final int positionsRemaining;
  final String? status;
  final int? addressId;
  final String? cityName;
  final DateTime? createdAt;

  VolunteerJob({
    this.volunteerJobId = 0,
    this.organisationProfileId = 0,
    this.organisationName,
    this.categoryId,
    this.categoryName,
    this.title = '',
    this.description,
    this.requirements,
    this.startDate,
    this.endDate,
    this.isRemote = false,
    this.positionsAvailable = 0,
    this.positionsFilled = 0,
    this.positionsRemaining = 0,
    this.status,
    this.addressId,
    this.cityName,
    this.createdAt,
  });

  factory VolunteerJob.fromJson(Map<String, dynamic> json) => VolunteerJob(
        volunteerJobId: json['volunteerJobId'] ?? 0,
        organisationProfileId: json['organisationProfileId'] ?? 0,
        organisationName: json['organisationName'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        title: json['title'] ?? '',
        description: json['description'],
        requirements: json['requirements'],
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'])
            : null,
        isRemote: json['isRemote'] ?? false,
        positionsAvailable: json['positionsAvailable'] ?? 0,
        positionsFilled: json['positionsFilled'] ?? 0,
        positionsRemaining: json['positionsRemaining'] ?? 0,
        status: json['status'],
        addressId: json['addressId'],
        cityName: json['cityName'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'volunteerJobId': volunteerJobId,
        'organisationProfileId': organisationProfileId,
        'organisationName': organisationName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'title': title,
        'description': description,
        'requirements': requirements,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isRemote': isRemote,
        'positionsAvailable': positionsAvailable,
        'positionsFilled': positionsFilled,
        'positionsRemaining': positionsRemaining,
        'status': status,
        'addressId': addressId,
        'cityName': cityName,
        'createdAt': createdAt?.toIso8601String(),
      };
}
