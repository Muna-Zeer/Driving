import 'dart:convert';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/models/levelModel.dart';
import 'package:driving_quiz_app/services/AdminService.dart';
import 'package:driving_quiz_app/services/LevelService.dart';
import 'package:driving_quiz_app/views/CategoriesScreen.dart';
import 'package:driving_quiz_app/views/ManageLevelScreen.dart';
import 'package:driving_quiz_app/views/ManageQuestionDialog.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter/material.dart';

class CategoryLevelsDashboardScreen extends StatefulWidget {
  final CategoryModel category;
  final List<dynamic> supportedLanguages;

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
  List<Level> levels = [];
  bool _isLoading = true;
  final LevelService _apiService = LevelService();
  AdminService _authService = AdminService();
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    loadLevelData();
    _initRole();
  }

  Future<void> _initRole() async {
    await _authService.loadUserRole();
    setState(() {
      _isLoadingRole = false;
    });
  }

  Future<void> loadLevelData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService.fetchLevelsForCategory(widget.category.id);

      setState(() {
        levels = data;
        _isLoading = false;
      });
    } catch (e) {
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
    final isAdmin = _authService.isAdmin;
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: const CustomResponsiveNavbar(),
            floatingActionButton: isAdmin
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ManageLevelScreen(category: widget.category)),
                      );
                    },
                    backgroundColor: AppColors.primaryGreen,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة قسم جديد',
                        style: TextStyle(color: Colors.white)),
                  )
                : null,
            endDrawer: MediaQuery.of(context).size.width < BreakPoint.tableMax
                ? buildMobileDrawer()
                : null,
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF7CB342))))
                : levels.isEmpty
                    ? Center(
                        child: Text(isArabic
                            ? 'لا توجد مستويات متاحة حاليا'
                            : "No Levels are Available"))
                    : LayoutBuilder(builder: (context, constraints) {
                        int crossAxisCount = 1;
                        double childAspectRatio = 3.8;

                        if (BreakPoint.isDesktop(constraints.maxWidth)) {
                          crossAxisCount = 2;
                          childAspectRatio = 3.5;
                        } else if (BreakPoint.isTablet(constraints.maxWidth)) {
                          crossAxisCount = 2;
                          childAspectRatio = 3.2;
                        }

                        return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: GridView.builder(
                                    itemCount: levels.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 8500,
                                      mainAxisExtent: 80,
                                      crossAxisSpacing: 12.0,
                                      mainAxisSpacing: 12.0,
                                    ),
                                    itemBuilder: (context, index) {
                                      final level = levels[index];
                                      final String levelName =
                                          (level.name != null &&
                                                  level.name!.isNotEmpty)
                                              ? level.name!
                                              : categoryName;
                                      return Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 14.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            child: InkWell(
                                                // Navigation handler triggered when tapping the card
                                                onTap: () {
                                                  if (isAdmin) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ManageQuestionDialog(
                                                                levelId: level
                                                                    .id
                                                                    .toString()),
                                                      ),
                                                    );
                                                  } else {
                                                    // Navigator.push(
                                                    //   context,
                                                    //   MaterialPageRoute(
                                                    //     builder: (context) => UserQuizScreen(levelId: level.id.toString()),
                                                    //   ),
                                                    // );
                                                  }
                                                },
                                                child: Container(
                                                    decoration: const BoxDecoration(
                                                        border: Border(
                                                            bottom: BorderSide(
                                                                color: Color(
                                                                    0xFF558B2F),
                                                                width: 6))),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 42,
                                                          height: 42,
                                                          decoration:
                                                              const BoxDecoration(
                                                                  color: AppColors
                                                                      .surface,
                                                                  shape: BoxShape
                                                                      .circle),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                              '${level.levelNumber}',
                                                              style:
                                                                  const TextStyle(
                                                                color: AppColors
                                                                    .primaryGreen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                              )),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                            child: Text(
                                                          '$levelName ${level.levelNumber}',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )),
                                                        if (isAdmin)
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons.edit,
                                                                    color: Colors
                                                                        .white70),
                                                                onPressed: () =>
                                                                    _openLevelForm(
                                                                        level),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .white70),
                                                                onPressed: () =>
                                                                    handleDeleteLevel(
                                                                        context,
                                                                        level.id
                                                                            .toString()),
                                                              )
                                                            ],
                                                          )
                                                      ],
                                                    ))),
                                          ));
                                    },
                                  )),
                            ));
                      })));
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
    if (refresh == true) loadLevelData();
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

        loadLevelData();
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
