class CategoryModel {
  final String id;
  final String name;
  final String Image_Url;
  final int order;

  CategoryModel(
      {required this.id,
      required this.name,
      required this.Image_Url,
      required this.order});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? json['translations']?[0]?['name'] ?? 'Unknown',
        Image_Url: json['image_url'] ?? '',
        order: json['order'] ?? 0);
  }
}
