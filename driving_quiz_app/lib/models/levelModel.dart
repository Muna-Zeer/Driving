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
  String get nameAr => translations
      .firstWhere((t) => t.locale == 'ar',
          orElse: () => LevelTranslation(locale: 'ar', name: ''))
      .name;
  String get nameEn => translations
      .firstWhere((t) => t.locale == 'en',
          orElse: () => LevelTranslation(locale: 'en', name: ''))
      .name;

  factory Level.fromJson(Map<String, dynamic> json) {
    var list = json['translations'] as List;
    List<LevelTranslation> translationsList = list != null
        ? list.map((l) => LevelTranslation.fromJson(l)).toList()
        : [];
    return Level(
      id: json['id'],
      groupKey: json['group_key'],
      levelNumber: json['level_number'] ?? 1,
      questionCount: json['questions_count'] ?? 0,
      order: json['order'] ?? 1,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      categoryId: json['category_id'],
      translations: translationsList,
    );
  }
  Map<String, dynamic> toJson() {
    // Converts the List<LevelTranslation> into a Map like {"ar": {"name": "sdsd"}, "en": {"name": ""}}
    final Map<String, dynamic> translationMap = {};
    for (var t in translations) {
      translationMap[t.locale] = {
        'name': t.name,
        if (t.description != null) 'description': t.description,
      };
    }

    return {
      if (id != null) 'id': id,
      'group_key': groupKey,
      'level_number': levelNumber,
      'question_count': questionCount,
      'order': order,
      'is_active': isActive,
      'category_id': categoryId,
      'translations': translationMap
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
