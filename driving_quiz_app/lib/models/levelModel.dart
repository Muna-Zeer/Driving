class Level {
  final int? id;
  final String? groupKey;
  final int levelNumber;
  final int questionCount;
  final int order;
  final bool isActive;
  final int? categoryId;
  final List<LevelTranslation> translations;
  Level({
    this.id,
    this.groupKey,
    required this.levelNumber,
    required this.questionCount,
    required this.order,
    required this.isActive,
    this.categoryId,
    required this.translations,
  });
}

class LevelTranslation {
  final int? id;
  final int? levelId;
  final String locale;
  final String name;
  final String? description;
  LevelTranslation({
    this.id,
    this.levelId,
    required this.locale,
    required this.name,
    this.description,
  });
  factory LevelTranslation.fromJson(Map<String, dynamic> json) {
    return LevelTranslation(
      id: json['id'],
      levelId: json['level_id'],
      locale: json['locale'],
      name: json['name'],
      description: json['description'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'locale': locale,
      'name': name,
      'description': description,
    };
  }
}
