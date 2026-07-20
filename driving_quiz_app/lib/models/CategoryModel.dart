import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final String? badgeAr;
  final String? badgeEn;
  final String type;
  final int order;

  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    this.badgeAr,
    this.badgeEn,
    required this.type,
    required this.order,
  });

  String getName(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? nameAr : nameEn;
  }

  String? getBadgeText(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? badgeAr : badgeEn;
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String categoryId = '';
    if (json['id'] != null) {
      categoryId = json['id'].toString();
    }

    String defaultName = json['name']?.toString() ?? 'Unknown';

    String nameArabic = defaultName;
    String nameEnglish = defaultName;
    String? badgeArabic;
    String? badgeEnglish;

    if (json['translations'] != null && json['translations'] is List) {
      final List<dynamic> transList = json['translations'];
      for (var item in transList) {
        if (item['locale'] == 'ar') {
          nameArabic = item['name'] ?? defaultName;
          badgeArabic = item['badge'];
        } else if (item['locale'] == 'en') {
          nameEnglish = item['name'] ?? defaultName;
          badgeEnglish = item['badge'];
        }
      }
    } else {
      if (json['name_ar'] != null) nameArabic = json['name_ar'].toString();
      if (json['name_en'] != null) nameEnglish = json['name_en'].toString();
      if (json['badge_ar'] != null) badgeArabic = json['badge_ar'].toString();
      if (json['badge_en'] != null) badgeEnglish = json['badge_en'].toString();
    }

    return CategoryModel(
      id: categoryId, // 🟢 هنا سيتم تخزين الـ Hash الحقيقي الكامل (مثل jR4vlO) وليس حرفاً واحداً
      imageUrl: json['image'] ?? json['image_url'] ?? '',
      type: json['type'] ?? 'standard',
      order: json['order'] is int
          ? json['order']
          : (int.tryParse(json['order']?.toString() ?? '0') ?? 0),
      nameAr: nameArabic,
      nameEn: nameEnglish,
      badgeAr: badgeArabic,
      badgeEn: badgeEnglish,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'image_url': imageUrl,
      'badge_ar': badgeAr,
      'badge_en': badgeEn,
      'type': type,
      'order': order,
    };
  }
}
