class Level {
  final String id;
  final String categoryId;
  final String groupKey;
  final int levelNumber;
  final int questionsCount;
  final bool isActive;
  final String? name;
  final String? description;
  final List<dynamic> translations; // Handles list safety

  Level({
    required this.id,
    required this.categoryId,
    required this.groupKey,
    required this.levelNumber,
    required this.questionsCount,
    required this.isActive,
    this.name,
    this.description,
    this.translations = const [],
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      groupKey: json['group_key']?.toString() ?? '',
      levelNumber: json['level_number'] is int
          ? json['level_number']
          : int.tryParse(json['level_number']?.toString() ?? '0') ?? 0,
      questionsCount: json['questions_count'] is int
          ? json['questions_count']
          : int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      // ✅ NULL-SAFE LIST CASTING: Fallback to [] if 'translations' is null
      translations: (json['translations'] is List) 
          ? json['translations'] as List<dynamic> 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'group_key': groupKey,
      'level_number': levelNumber,
      'questions_count': questionsCount,
      'is_active': isActive,
      'name': name,
      'description': description,
      'translations': translations,
    };
  }
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
      if (id != null) 'id': id,
      if (levelId != null) 'level_id': levelId,
      'locale': locale,
      'name': name,
      if (description != null) 'description': description,
    };
  }
}
