class VolunteerJobUpdateRequest {
  final int? categoryId;
  final int? addressId;
  final String title;
  final String? description;
  final String? requirements;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRemote;
  final int positionsAvailable;
  final String? status;

  VolunteerJobUpdateRequest({
    this.categoryId,
    this.addressId,
    required this.title,
    this.description,
    this.requirements,
    this.startDate,
    this.endDate,
    this.isRemote = false,
    required this.positionsAvailable,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'addressId': addressId,
        'title': title,
        'description': description,
        'requirements': requirements,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isRemote': isRemote,
        'positionsAvailable': positionsAvailable,
        'status': status,
      };
}
