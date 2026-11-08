
class QuestionTranslation {
  final String locale;
  final String text;

  const QuestionTranslation({
    required this.locale,
    required this.text,
  });

  factory QuestionTranslation.fromJson(Map<String, dynamic> json) {
    return QuestionTranslation(
      locale: normalizeLocale(json['locale']),
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'locale': locale,
        'text': text,
      };
}

class OptionTranslation extends QuestionTranslation {
  const OptionTranslation({
    required super.locale,
    required super.text,
  });

  factory OptionTranslation.fromJson(Map<String, dynamic> json) {
    return OptionTranslation(
      locale: normalizeLocale(json['locale']),
      text: json['text']?.toString() ?? '',
    );
  }
}

/// Keep locale normalization consistent with Laravel QuestionResource
/// and OptionResource.
String normalizeLocale(dynamic value) {
  switch (value?.toString().trim().toLowerCase()) {
    case '0':
    case 'ar':
      return 'ar';
    case '1':
    case 'en':
      return 'en';
    default:
      return '';
  }
}

String localizedText(
  List<QuestionTranslation> translations,
  String requestedLocale,
) {
  final locale = normalizeLocale(requestedLocale);

  final selected = translations.where(
    (item) => item.locale == locale && item.text.trim().isNotEmpty,
  );

  if (selected.isNotEmpty) return selected.first.text;

  // Fallback to the other available language.
  final fallback = translations.where(
    (item) => item.text.trim().isNotEmpty,
  );

  return fallback.isNotEmpty ? fallback.first.text : '';
}

class OptionModel {
  final String identifier;
  final bool isCorrect;
  final List<OptionTranslation> translations;
  final String? imageUrl;

  const OptionModel({
    required this.identifier,
    required this.isCorrect,
    required this.translations,
    this.imageUrl,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['all_option_translations'] ??
        json['translations'] ??
        [];

    final translations = <OptionTranslation>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final translation = OptionTranslation.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (translation.locale.isNotEmpty) {
            translations.add(translation);
          }
        }
      }
    }

    // Legacy response fallback.
    if (translations.isEmpty &&
        (json['text']?.toString().trim().isNotEmpty ?? false)) {
      translations.add(
        OptionTranslation(
          locale: 'en',
          text: json['text'].toString(),
        ),
      );
    }

    return OptionModel(
      identifier: json['identifier']?.toString() ?? '',
      isCorrect: json['is_correct'] == true ||
          json['is_correct'] == 1 ||
          json['is_correct'] == '1',
      imageUrl: json['image_url']?.toString(),
      translations: translations,
    );
  }

  String getText(String locale) {
    return localizedText(translations, locale);
  }

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'is_correct': isCorrect,
        'image_url': imageUrl,
        'translations': translations
            .where((t) => t.text.trim().isNotEmpty)
            .map((t) => t.toJson())
            .toList(),
      };
}

class QuestionModel {
  final String? id;
  final String levelId;
  final String? imageUrl;
  final int order;
  final List<QuestionTranslation> translations;
  final List<OptionModel> options;

  const QuestionModel({
    this.id,
    required this.levelId,
    this.imageUrl,
    required this.order,
    required this.translations,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['all_question_translations'] ??
        json['translations'] ??
        [];

    final translations = <QuestionTranslation>[];

    if (rawTranslations is List) {
      for (final item in rawTranslations) {
        if (item is Map) {
          final translation = QuestionTranslation.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (translation.locale.isNotEmpty) {
            translations.add(translation);
          }
        }
      }
    }

    // Legacy response fallback.
    if (translations.isEmpty &&
        (json['question']?.toString().trim().isNotEmpty ?? false)) {
      translations.add(
        QuestionTranslation(
          locale: 'en',
          text: json['question'].toString(),
        ),
      );
    }

    final rawOptions = json['options'] as List? ?? [];

    return QuestionModel(
      id: json['id']?.toString(),
      levelId: json['level_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      order: int.tryParse(json['order']?.toString() ?? '') ?? 1,
      translations: translations,
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) => OptionModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  String getTitle(String locale) {
    return localizedText(translations, locale);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'level_id': levelId,
        'order': order,
        'image_url': imageUrl,
        'translations': translations
            .where((t) => t.text.trim().isNotEmpty)
            .map((t) => t.toJson())
            .toList(),
        'options': options.map((o) => o.toJson()).toList(),
      };
}
