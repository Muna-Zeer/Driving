import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/services/CategoryService.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryAPI _apiService = CategoryAPI();
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomResponsiveNavbar(),
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
                  final categories = snapshot.data!;
                  return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24),
                      child: Center(
                          child: Container(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16.0,
                                        mainAxisSpacing: 16.0,
                                        childAspectRatio: 1.2),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  return _buildCategoryCard(categories[index]);
                                },
                              ))));
                });
          }),
        ));
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

// Your cleanly styled Category Item block
Widget _buildCategoryCard(CategoryModel category) {
  return Card(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4.0),
      side: const BorderSide(color: AppColors.border, width: 1),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () {
        // Add routing here later!
      },
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: category.Image_Url.isNotEmpty
                  ? Image.network(
                      category.Image_Url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: AppColors.textSecondary),
                    )
                  : const Icon(Icons.directions_car,
                      size: 40, color: AppColors.textSecondary),
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              category.name,
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
    ),
  );
}
