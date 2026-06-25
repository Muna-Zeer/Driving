import 'dart:convert';

import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/services/CategoryService.dart';
import 'package:driving_quiz_app/views/CreateCategoryScreen.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomPagination.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryAPI _apiService = CategoryAPI();
  late Future<List<CategoryModel>> _categoriesFuture;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  String _userRole = '';
  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin';
  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    String? role = await _storage.read(key: 'user_role');
    if (role != null) {
      setState(() {
        _userRole = role.trim();
      });
    }
  }

  void handleDeleteCategory(BuildContext context, String hashedId) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    bool confirmDelete = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
            content: Text(isArabic
                ? 'هل أنت متأكد من حذف هذه الفئة نهائياً؟ سيتم إعادة ترتيب باقي الفئات تلقائياً.'
                : 'Are you sure you want to delete this category?'),
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
      final response = await _apiService.deleteCategoryFromAPI(hashedId);
      print('Hashed ID to delete: $hashedId');
      if (response.statusCode == 200) {
        if (!context.mounted) return;
        AppAlerts.showAlert(context,
            isArabic ? 'تم حذف الفئة بنجاح' : 'Category deleted successfully');

        setState(() {
          _categoriesFuture = _apiService.fetchCategories();
        });
      } else {
        if (!context.mounted) return;
        final decodedResponse = jsonDecode(response.body);
        String errorMsg = decodedResponse['message'] ??
            (isArabic ? 'فشل في حذف الفئة' : 'Failed to delete category');
        AppAlerts.showError(context, errorMsg);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppAlerts.showError(context,
          isArabic ? 'خطأ في الاتصال بالشبكة: $e' : 'Network Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          builder: (context) => const CreateCategoryScreen()),
                    );
                  },
                  backgroundColor: AppColors.primaryGreen,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('إضافة قسم جديد',
                      style: TextStyle(color: Colors.white)),
                )
              : null,
          endDrawer: MediaQuery.of(context).size.width < BreakPoint.tableMax
              ? _buildMobileDrawer()
              : null,
          body: LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = 2;
            if (BreakPoint.isDesktop(constraints.maxWidth)) {
              crossAxisCount = 5;
            } else if (BreakPoint.isTablet(constraints.maxWidth)) {
              crossAxisCount = 3;
            }

            return FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryGreen));
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('خطأ في تحميل البيانات:${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('لا توجد اقسام  متاحةحاليا'));
                  }
                  final allCategories = snapshot.data!;
                  final int totalPages =
                      (allCategories.length / _itemsPerPage).ceil();

                  final int startIndex = (_currentPage - 1) * _itemsPerPage;
                  final int endIndex = startIndex + _itemsPerPage;

                  final List<CategoryModel> visibleCategories =
                      allCategories.sublist(
                    startIndex,
                    endIndex > allCategories.length
                        ? allCategories.length
                        : endIndex,
                  );

                  return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24),
                      child: Center(
                        child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Column(children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16.0,
                                        mainAxisSpacing: 16.0,
                                        childAspectRatio: 1.2),
                                itemCount: visibleCategories.length,
                                itemBuilder: (context, index) {
                                  return _buildCategoryCard(
                                    context,
                                    visibleCategories[index],
                                    isAdmin,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              CustomPagination(
                                  currentPage: _currentPage,
                                  totalPages: totalPages,
                                  onPageChanged: (newPage) {
                                    setState(() {
                                      _currentPage = newPage;
                                    });
                                  }),
                            ])),
                      ));
                });
          }),
        ));
  }

  Widget _buildCategoryCard(
      BuildContext context, CategoryModel category, bool showAdmin) {
    final currentBadge = category.getBadgeText(context);
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Builder(
                      builder: (context) {
                        String dbImageValue = category.imageUrl.toLowerCase();

                        if (dbImageValue.isEmpty) {
                          return const Icon(
                            Icons.directions_car,
                            size: 40,
                            color: AppColors.textSecondary,
                          );
                        }

                        if (dbImageValue.contains('car.png')) {
                          dbImageValue = 'car.png';
                        } else if (dbImageValue.contains('truck.png')) {
                          dbImageValue = 'truck.png';
                        } else if (dbImageValue.contains('taxi.png') ||
                            dbImageValue.contains('tractor')) {
                          dbImageValue = 'taxi.png';
                        } else if (dbImageValue.contains('motorcycle.png')) {
                          dbImageValue = 'motorcycle.png';
                        }

                        IconData displayIcon = Icons.image_not_supported;

                        if (dbImageValue.contains('car.png')) {
                          displayIcon = Icons.directions_car;
                        } else if (dbImageValue.contains('truck.png')) {
                          displayIcon = Icons.local_shipping;
                        } else if (dbImageValue.contains('taxi.png')) {
                          displayIcon = Icons.local_taxi;
                        } else if (dbImageValue.contains('motorcycle.png')) {
                          displayIcon = Icons.two_wheeler;
                        }

                        return Icon(
                          displayIcon,
                          size: 40,
                          color: AppColors.textSecondary,
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    category.getName(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (currentBadge != null && currentBadge.isNotEmpty)
              PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentBadge,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ))),
            if (showAdmin)
              Positioned(
                top: 4,
                left: 4,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.textLight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit,
                            size: 16, color: AppColors.primaryGreen),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    CreateCategoryScreen(category: category)),
                          ).then((wasUpdated) {
                            if (wasUpdated == true) {
                              setState(() {
                                _categoriesFuture =
                                    _apiService.fetchCategories();
                              });
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withAlpha(230),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete,
                            size: 16, color: Colors.red),
                        onPressed: () {
                          handleDeleteCategory(context, category.id.toString());
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMobileDrawer() {
  return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
    const DrawerHeader(
        decoration: BoxDecoration(color: AppColors.primaryGreen),
        child: Text('القائمة',
            style: TextStyle(color: AppColors.surface, fontSize: 24))),
    ListTile(title: const Text('الرئيسية'), onTap: () {}),
    ListTile(title: const Text('أسئلة التووريا'), onTap: () {}),
    ListTile(title: const Text('امتحان التجريبي '), onTap: () {}),
    ListTile(title: const Text('اتصل بنا  '), onTap: () {}),
  ]));
}
