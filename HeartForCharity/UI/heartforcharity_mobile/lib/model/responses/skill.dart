class Skill {
  final int skillId;
  final String name;
  final String? description;

  Skill({required this.skillId, required this.name, this.description});

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        skillId: json['skillId'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
      );
}
