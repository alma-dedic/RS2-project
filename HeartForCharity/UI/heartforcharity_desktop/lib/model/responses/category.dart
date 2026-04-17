class Category {
  final int categoryId;
  final String name;
  final String? description;
  final String? appliesTo;

  Category({
    this.categoryId = 0,
    this.name = '',
    this.description,
    this.appliesTo,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: json['categoryId'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        appliesTo: json['appliesTo'],
      );

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'appliesTo': appliesTo,
      };
}
