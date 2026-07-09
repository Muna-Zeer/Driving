import 'dart:convert';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/models/levelModel.dart';
import 'package:driving_quiz_app/services/LevelService.dart';
import 'package:driving_quiz_app/views/ManageLevelScreen.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter/material.dart';

class CategoryLevelsDashboardScreen extends StatefulWidget {
  final CategoryModel category;
  final List<dynamic> supportedLanguages;
  final _userRole = '';
  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin';

  const CategoryLevelsDashboardScreen({
    Key? key,
    required this.category,
    required this.supportedLanguages,
  }) : super(key: key);

  @override
  State<CategoryLevelsDashboardScreen> createState() =>
      _CategoryLevelsDashboardScreenState();
}

class _CategoryLevelsDashboardScreenState
    extends State<CategoryLevelsDashboardScreen> {
  List<Level> _levels = [];
  bool _isLoading = true;
  final LevelService _apiService = LevelService();
  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print("Fetching levels for Category ID: ${widget.category.id}");
      final data = await _apiService.fetchLevelsForCategory(widget.category.id);

      print("Parsed Levels Count: ${data.length}"); // Look for this in console!

      setState(() {
        _levels = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error parsing level objects: $e");
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error Downloading levels $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String categoryName = widget.category.nameAr ?? 'تؤوريا';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text('إدارة مستويات: $categoryName'),
            centerTitle: true,
            actions: [
              TextButton.icon(
                onPressed: _levels.length >= 30
                    ? null
                    : () async {
                        final bool? refresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageLevelScreen(
                              category: widget.category,
                            ),
                          ),
                        );
                        if (refresh == true) _loadLevelData();
                      },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة مستوى جديد',
                    style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  backgroundColor:
                      _levels.length >= 30 ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF7CB342))))
              : _levels.isEmpty
                  ? Center(
                      child: Text(isArabic
                          ? 'لا توجد مستويات متاحة حاليا'
                          : "No Levels are Available"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      itemCount: _levels.length,
                      itemBuilder: (context, index) {
                        final level = _levels[index];
                        final String levelName =
                            (level.name != null && level.name!.isNotEmpty)
                                ? level.name!
                                : categoryName;
                        return Container(
                            margin: const EdgeInsets.only(bottom: 14.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7CB342),
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF558B2F),
                                              width: 6))),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: const BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text('${level.levelNumber}',
                                            style: const TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            )),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(
                                        '$levelName ${level.levelNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                      if (widget.isAdmin)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.white70),
                                              onPressed: () =>
                                                  _openLevelForm(level),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.white70),
                                              onPressed: () =>
                                                  handleDeleteLevel(context,
                                                      level.id.toString()),
                                            )
                                          ],
                                        )
                                    ],
                                  )),
                            ));
                      },
                    ),
        ));
  }

  void _openLevelForm(Level? level) async {
    Map<String, dynamic>? mappedData;
    if (level != null) {
      mappedData = level.toJson();
    }

    final bool? refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLevelScreen(
          category: widget.category,
          level: mappedData,
        ),
      ),
    );
    if (refresh == true) _loadLevelData();
  }

  void handleDeleteLevel(BuildContext context, String hashedId) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    bool confirmDelete = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
            content: Text(isArabic
                ? 'هل أنت متأكد من حذف هذا المستوى نهائياً؟ سيتم إعادة ترتيب باقي المستويات تلقائياً.'
                : 'Are you sure you want to delete this level?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  isArabic ? 'حذف' : 'Delete',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      final response = await _apiService.deleteLevelFromAPI(hashedId);
      if (response.statusCode == 200) {
        if (!context.mounted) return;
        AppAlerts.showAlert(context,
            isArabic ? 'تم حذف الفئة بنجاح' : 'Category deleted successfully');

        // setState(() {
        //   _levelsFuture =
        //       _apiService.fetchLevelsForCategory(widget.category.id);
        // });
      } else {
        if (!context.mounted) return;
        final decodedResponse = jsonDecode(response.body);
        String errorMsg = decodedResponse['message'] ??
            (isArabic ? 'فشل في حذف المستوى' : 'Failed to delete level');
        AppAlerts.showError(context, errorMsg);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppAlerts.showError(context,
          isArabic ? 'خطأ في الاتصال بالشبكة: $e' : 'Network Error: $e');
    }
  }
}
