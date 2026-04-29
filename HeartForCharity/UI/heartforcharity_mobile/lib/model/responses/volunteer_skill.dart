class VolunteerSkill {
  final int volunteerSkillId;
  final int userProfileId;
  final int skillId;
  final String skillName;
  final String? skillDescription;

  VolunteerSkill({
    required this.volunteerSkillId,
    required this.userProfileId,
    required this.skillId,
    required this.skillName,
    this.skillDescription,
  });

  factory VolunteerSkill.fromJson(Map<String, dynamic> json) => VolunteerSkill(
        volunteerSkillId: json['volunteerSkillId'] ?? 0,
        userProfileId: json['userProfileId'] ?? 0,
        skillId: json['skillId'] ?? 0,
        skillName: json['skillName'] ?? '',
        skillDescription: json['skillDescription'],
      );
}
