class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final String? badgeAr;
  final String? badgeEn;
  final String Type;

  final int order;

  CategoryModel(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.imageUrl,
      this.badgeAr,
      this.badgeEn,
      required this.Type,
      required this.order});

  String get name {
    return nameAr;
  }

  String? get badgeText {
    return badgeAr;
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
        id: json['id']?.toString() ?? '',
        badgeAr: json['badge_ar'],
        nameAr: json['name_ar'] ??
            json['translations']?[0]?['name_ar'] ??
            'Unknown',
        nameEn: json['name_en'] ??
            json['translations']?[0]?['name_en'] ??
            'Unknown',
        badgeEn: json['badge_en'],
        imageUrl: json['image_url'] ?? '',
        Type: json['type'] ?? "",
        order: json['order'] ?? 0);
  }
}
