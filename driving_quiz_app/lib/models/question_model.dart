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
    return <String, dynamic>{
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
    return <String, dynamic>{
      'locale': locale,
      'text': text,
    };
  }
}

class OptionModel {
  final String identifier; // Uses A, B, C, D as the unique identifier
  final bool isCorrect;
  final List<OptionTranslation> translations;
  final String? imageUrl;

  OptionModel({
    required this.identifier,
    required this.isCorrect,
    required this.translations,
    this.imageUrl,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    var translationList = json['all_option_translations'] as List? ?? [];
    List<OptionTranslation> parsedTranslations =
        translationList.map((t) => OptionTranslation.fromJson(t)).toList();

    return OptionModel(
      identifier: json['identifier'] ?? '',
      imageUrl: json['image_url'],
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
    return <String, dynamic>{
      'identifier': identifier,
      'is_correct': isCorrect,
      'image_url': imageUrl,
      'translations': translations.map((t) => t.toJson()).toList(),
    };
  }
}

class QuestionModel {
  final String? id;
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
          imageUrl: o['image_url'],
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

    final arTrans = translations.firstWhere(
      (t) => t.locale == 'ar',
      orElse: () => QuestionTranslation(locale: 'ar', text: ''),
    );

    return <String, dynamic>{
      'id': id,
      'level_id': levelId,
      'order': order,
      'image_url': imageUrl,
      'question_text': <String, dynamic>{
        'en': enTrans.text,
        'ar': arTrans.text,
      },
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}
