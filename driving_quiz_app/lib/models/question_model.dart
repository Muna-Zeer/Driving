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
  final int? id;
  final String identifier;
  final bool isCorrect;
  final List<OptionTranslation> translations;

  OptionModel({
    this.id,
    required this.identifier,
    required this.isCorrect,
    required this.translations,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    var translationList = json['translations'] as List? ?? [];
    List<OptionTranslation> parsedTranslations =
        translationList.map((t) => OptionTranslation.fromJson(t)).toList();

    return OptionModel(
      id: json['id'],
      identifier: json['identifier'] ?? '',
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      translations: parsedTranslations,
    );
  }

  Map<String, dynamic> toJson() {

    final Map<String, dynamic> translationMap = {};
    for (var t in translations) {
      translationMap[t.locale] = t.text;
    }

    return {
      'identifier': identifier,
      'is_correct': isCorrect,
      'translations': translationMap,
    };
  }
}

class QuestionModel {
  final int? id;
  final int levelId;
  final String? imageUrl;
  final List<QuestionTranslation> translations;
  final List<OptionModel> options;

  QuestionModel({
    this.id,
    required this.levelId,
    this.imageUrl,
    required this.translations,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var qTransList = json['translations'] as List? ?? [];
    List<QuestionTranslation> parsedQTrans =
        qTransList.map((t) => QuestionTranslation.fromJson(t)).toList();

    var optList = json['options'] as List? ?? [];
    List<OptionModel> parsedOptions =
        optList.map((o) => OptionModel.fromJson(o)).toList();

    return QuestionModel(
      id: json['id'],
      levelId: json['level_id'] is int 
          ? json['level_id'] 
          : int.parse(json['level_id'].toString()),
      imageUrl: json['image_url'],
      translations: parsedQTrans,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> qTransMap = {};
    for (var t in translations) {
      qTransMap[t.locale] = t.text;
    }

    return {
      'level_id': levelId,
      'image_url': imageUrl,
      'question_text': qTransMap,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}