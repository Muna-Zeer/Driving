class QuestionTranslation {
  final String locale;
  final String text;

  QuestionTranslation({required this.locale, required this.text});

  factory QuestionTranslation.fromJson(Map<String, dynamic> json) {
    return QuestionTranslation(
      locale: json['locale'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'text': text,
    };
  }
}

class OptionTranslation {
  final String locale;
  final String text;

  OptionTranslation({required this.locale, required this.text});

  factory OptionTranslation.fromJson(Map<String, dynamic> json) {
    return OptionTranslation(
      locale: json['locale'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'text': text,
    };
  }
}

class OptionModel {
  final String identifier; // Uses A, B, C, D as the unique identifier
  final bool isCorrect;
  final List<OptionTranslation> translations;

  OptionModel({
    required this.identifier,
    required this.isCorrect,
    required this.translations,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    // Updated to match your API key 'all_option_translations'
    var translationList = json['all_option_translations'] as List? ?? [];
    List<OptionTranslation> parsedTranslations =
        translationList.map((t) => OptionTranslation.fromJson(t)).toList();

    return OptionModel(
      identifier: json['identifier'] ?? '',
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      translations: parsedTranslations,
    );
  }

  String getText(String locale) {
    final translation = translations.firstWhere(
      (t) => t.locale == locale,
      orElse: () => translations.isNotEmpty
          ? translations.first
          : OptionTranslation(locale: '', text: ''),
    );
    return translation.text;
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'is_correct': isCorrect,
      'translations': translations.map((t) => t.toJson()).toList(),
    };
  }
}

class QuestionModel {
  final String?
      id; // Changed to String? to handle string/hashed IDs like "oyqY"
  final String levelId;
  final String? imageUrl;
  final int order;
  final List<QuestionTranslation> translations;
  final List<OptionModel> options;

  QuestionModel({
    this.id,
    required this.levelId,
    this.imageUrl,
    required this.order,
    required this.translations,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var transList =
        json['all_question_translations'] ?? json['translations'] ?? [];
    var optionsList = json['options'] as List? ?? [];

    return QuestionModel(
      id: json['id']?.toString(),
      levelId: json['level_id'].toString(),
      imageUrl: json['image_url'],
      order: json['order'] ?? 1,
      translations: (transList as List)
          .map((t) => QuestionTranslation.fromJson(t))
          .toList(),
      options: optionsList.map((o) {
        var optTrans = o['all_option_translations'] ?? o['translations'] ?? [];
        return OptionModel(
          identifier: o['identifier'],
          isCorrect: o['is_correct'] ?? false,
          translations: (optTrans as List)
              .map((ot) => OptionTranslation.fromJson(ot))
              .toList(),
        );
      }).toList(),
    );
  }
  String getTitle(String locale) {
    final translation = translations.firstWhere(
      (t) => t.locale == locale,
      orElse: () => translations.isNotEmpty
          ? translations.first
          : QuestionTranslation(locale: '', text: ''),
    );
    return translation.text;
  }

  Map<String, dynamic> toJson() {
    final enTrans = translations.firstWhere(
      (t) => t.locale == 'en',
      orElse: () => QuestionTranslation(locale: 'en', text: ''),
    );
    final arTrans = translations.firstWhere((t) => t.locale == 'ar',
        orElse: () => QuestionTranslation(locale: 'ar', text: ''));
    return {
      'id': id,
      'level_id': levelId,
      'order': order,
      'image_url': imageUrl,
      'question_text': {
        'en': enTrans.text,
        'ar': arTrans.text,
      },
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}
