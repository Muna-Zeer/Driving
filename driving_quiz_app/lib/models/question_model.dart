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
  final String? id; // Changed to String? to handle string/hashed IDs like "oyqY"
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
    // Updated to match your API key 'all_question_translations'
    var qTransList = json['all_question_translations'] as List? ?? [];
    List<QuestionTranslation> parsedQTrans =
        qTransList.map((t) => QuestionTranslation.fromJson(t)).toList();

    var optList = json['options'] as List? ?? [];
    List<OptionModel> parsedOptions =
        optList.map((o) => OptionModel.fromJson(o)).toList();

    return QuestionModel(
      id: json['id']?.toString(),
      levelId: json['level_id']?.toString() ?? '',
      imageUrl: json['image_url'],
      order: json['order'] ?? 1, 
      translations: parsedQTrans,
      options: parsedOptions,
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
    return {
      'level_id': levelId,
      'image_url': imageUrl,
      'order': order,
      'translations': translations.map((t) => t.toJson()).toList(),
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}