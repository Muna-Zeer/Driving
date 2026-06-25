import 'dart:convert';

import 'package:driving_quiz_app/CategoriesIcons.dart';
import 'package:driving_quiz_app/SupportedLanguages.dart';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/services/CategoryService.dart';
import 'package:driving_quiz_app/typeWidget.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  const CreateCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _badgeControllers = {};

  final TextEditingController _imageURLController = TextEditingController();
  final TextEditingController _typeController =
      TextEditingController(text: 'car');

  CategoryAPI _categoryAPI = CategoryAPI();
  IconData? _selectedIcon;
  bool get isEditMode => widget.category != null;
  bool _isLoading = false;
  bool _isActive = true;
  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: supportedLanguages.length, vsync: this);

    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      String initialName = '';
      String? initialBadge;

      if (isEditMode) {
        initialName = langCode == 'ar'
            ? widget.category!.nameAr
            : widget.category!.nameEn;
        initialBadge = langCode == 'ar'
            ? widget.category!.badgeAr
            : widget.category!.badgeEn;
      }
      _nameControllers[langCode] = TextEditingController(text: initialName);
      _badgeControllers[langCode] =
          TextEditingController(text: initialBadge ?? '');
    }
    if (isEditMode) {
      _typeController.text = widget.category!.type;
      final img = widget.category!.imageUrl;
      if (img.contains('car.png')) {
        _selectedIcon = Icons.directions_car;
      } else if (img.contains('truck.png')) {
        _selectedIcon = Icons.local_shipping;
      } else if (img.contains('taxi.png')) {
        _selectedIcon = Icons.local_taxi;
      } else if (img.contains('motorcycle.png')) {
        _selectedIcon = Icons.two_wheeler;
      }
    }
  }

  @override
  void dispose() {
    _imageURLController.dispose();
    _tabController.dispose();
    _typeController.dispose();
    _nameControllers.forEach((_, c) => c.dispose());
    _badgeControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    List<Map<String, dynamic>> translationsPayload = [];
    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      final String nameText = _nameControllers[langCode]?.text.trim() ?? '';
      final String badgeText = _badgeControllers[langCode]?.text.trim() ?? '';
      translationsPayload.add({
        "locale": langCode,
        "name": nameText,
        "badge": badgeText.isEmpty ? null : badgeText,
      });
    }

    String? imageName;
    if (_selectedIcon == Icons.directions_car)
      imageName = 'car.png';
    else if (_selectedIcon == Icons.local_shipping)
      imageName = 'truck.png';
    else if (_selectedIcon == Icons.local_taxi)
      imageName = 'taxi.png';
    else if (_selectedIcon == Icons.two_wheeler) imageName = 'motorcycle.png';

    if (imageName == null && isEditMode) {
      imageName = widget.category!.imageUrl;
    }
    final Map<String, dynamic> newCategoryPayload = {
      "translations": translationsPayload,
      "image_url": imageName,
      "type": _typeController.text,
      "is_active": _isActive
    };
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      http.Response response;
      if (isEditMode) {
        response = await _categoryAPI.updateCategoryInAPI(
            widget.category!.id, newCategoryPayload);
      } else {
        response = await _categoryAPI.sendCategoryToAPI(newCategoryPayload);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? (isEditMode
                      ? 'تم تحديث الفئة بنجاح'
                      : 'تمت إضافة الفئة بنجاح')
                  : (isEditMode
                      ? 'Category updated successfully'
                      : 'Category created successfully'),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        final decodedResponse = jsonDecode(response.body);
        String BackendErrorMsg = decodedResponse['message'] ??
            (isArabic ? 'فشل في إضافة القسم' : "Failed to add Category");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BackendErrorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic
              ? 'خطأ في الاتصال بالشبكة: $e'
              : 'Network Connection Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
            appBar: AppBar(
              title: const CustomResponsiveNavbar(),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.deepForest,
              elevation: 1,
            ),
            body: Center(
                child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 800, maxHeight: 750),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                        key: _formKey,
                        child: ListView(children: [
                          Container(
                            color: AppColors.textSecondary,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: AppColors.primaryGreen,
                              unselectedLabelColor: AppColors.textPrimary,
                              indicatorColor: AppColors.primaryGreen,
                              tabs: supportedLanguages.map((lang) {
                                final Map<String, dynamic> langMap =
                                    lang as Map<String, dynamic>;
                                return Tab(
                                    text: langMap['name']?.toString() ?? '');
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                              height: 200,
                              child: TabBarView(
                                  controller: _tabController,
                                  children: supportedLanguages.map((lang) {
                                    final Map<String, dynamic> langMap =
                                        lang as Map<String, dynamic>;
                                    final String langCode =
                                        langMap['code']?.toString() ?? 'en';
                                    return Column(
                                      children: [
                                        CustomTextField(
                                          controller:
                                              _nameControllers[langCode]!,
                                          labelText: isArabic
                                              ? 'اسم القسم (${langMap['name']}) *'
                                              : 'Category Name (${langMap['name']}) *',
                                          validator: (value) => value == null ||
                                                  value.trim().isEmpty
                                              ? (isArabic
                                                  ? 'يرجى إدخال اسم القسم'
                                                  : 'Please enter category name')
                                              : null,
                                        ),
                                        const SizedBox(height: 24),
                                        CustomTextField(
                                          controller:
                                              _badgeControllers[langCode]!,
                                          labelText: isArabic
                                              ? 'نص الشارة العلوية (${langMap['name']}) - اختياري'
                                              : 'Upper Badge Text (${langMap['name']}) - Optional',
                                        ),
                                      ],
                                    );
                                  }).toList())),
                          const Divider(thickness: 1.5, height: 32),
                          Text(
                              isArabic
                                  ? 'الإعدادات العامة للقسم'
                                  : 'General Sitting',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepForest)),
                          const Divider(),
                          // CustomTextField(
                          //   controller: _imageURLController,
                          //   labelText: isArabic
                          //       ? 'رابط الصورة (Image URL)'
                          //       : 'Image Url',
                          //   hintText: 'https://example.com/image.png',
                          // ),

                          const SizedBox(
                            height: 12,
                          ),
                          DropdownButtonFormField(
                            value: _typeController.text.isEmpty
                                ? 'car'
                                : _typeController.text,
                            decoration: InputDecoration(
                              labelText:
                                  isArabic ? 'نوع القسم' : 'Category Type',
                              labelStyle: const TextStyle(
                                  color: AppColors.primaryGreen),
                              border: const OutlineInputBorder(),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryGreen, width: 2),
                              ),
                            ),
                            items: typeOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(
                                    isArabic ? option['ar']! : option['en']!),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _typeController.text = newValue ?? 'car';
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? (isArabic
                                    ? 'يرجى تحديد النوع'
                                    : 'Please Enter category type')
                                : null,
                          ),

                          Text(
                            isArabic
                                ? 'اختر أيقونة القسم *'
                                : 'Select Category Icon *',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepForest),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Container(
                              height: 110,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: avaliableIcons.length,
                                  itemBuilder: (context, index) {
                                    final icon = avaliableIcons[index];
                                    final isSelected =
                                        _selectedIcon == icon['value'];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedIcon = null;
                                          } else {
                                            _selectedIcon =
                                                icon['value'] as IconData;
                                          }
                                        });
                                      },
                                      child: Container(
                                          width: 100,
                                          margin:
                                              const EdgeInsets.only(left: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryGreen
                                                    .withOpacity(0.1)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primaryGreen
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                icon['value'],
                                                size: 50,
                                                color: isSelected
                                                    ? AppColors.primaryGreen
                                                    : Colors.grey.shade700,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isArabic
                                                    ? icon['name']!
                                                    : icon['name_en']!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal),
                                              ),
                                            ],
                                          )),
                                    );
                                  })),
                          const SizedBox(height: 12),
                          Card(
                            color: AppColors.surface,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(
                                  color: AppColors.border, width: 1),
                            ),
                            child: SwitchListTile(
                                title: Text(
                                    isArabic ? 'حالة التفعيل ' : 'Is Active'),
                                subtitle: Text(isArabic
                                    ? 'تحديد ما إذا كان القسم سيظهر للمستخدمين مباشرة أم لا'
                                    : 'Determine whether this category is visible online'),
                                activeColor: AppColors.primaryGreen,
                                value: _isActive,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                }),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              isArabic
                                  ? 'حفظ وإدراج القسم'
                                  : 'Save and Publish',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]))))));
  }
}
