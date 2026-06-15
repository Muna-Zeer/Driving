import 'dart:convert';

import 'package:driving_quiz_app/CategoriesIcons.dart';
import 'package:driving_quiz_app/SupportedLanguages.dart';
import 'package:driving_quiz_app/services/CategoryService.dart';
import 'package:driving_quiz_app/typeWidget.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({Key? key}) : super(key: key);

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
  final TextEditingController _orderController =
      TextEditingController(text: '0');
  CategoryAPI _categoryAPI = CategoryAPI();
  String? _selectedIcon;

  bool _isLoading = false;
  bool _isActive = true;
  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: supportedLanguages.length, vsync: this);

    for (var lang in supportedLanguages) {
      _nameControllers[lang['code']!] = TextEditingController();
      _badgeControllers[lang['code']!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _imageURLController.dispose();
    _tabController.dispose();
    _typeController.dispose();
    _orderController.dispose();
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

    final Map<String, dynamic> newCategoryPayload = {
      "translations": translationsPayload,
      "image_url": _selectedIcon,
      // "image_url":
      //     _imageURLController.text.isEmpty ? null : _imageURLController.text,
      "type": _typeController.text,
      "order": int.tryParse(_orderController.text) ?? 0,
      "is_active": _isActive
    };
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final response = await _categoryAPI.sendCategoryToAPI(newCategoryPayload);
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تمت إضافة الفئة بنجاح'
                : 'Category created successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
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
                          CustomTextField(
                            controller: _orderController,
                            labelText: isArabic ? 'الترتيب (Order)' : 'Order',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return (isArabic
                                    ? 'يرجى إدخال الترتيب الرقمي'
                                    : 'Please Enter Order number');
                              if (int.tryParse(value) == null)
                                return (isArabic
                                    ? 'الترتيب يجب أن يكون رقماً صحيحاً'
                                    : 'Must be valid Number');
                              return null;
                            },
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
                                          _selectedIcon = icon['value'];
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
                                              SvgPicture.asset(
                                                'assets/images/${icon['value']}',
                                                height: 50,
                                                width: 50,
                                                placeholderBuilder:
                                                    (BuildContext context) =>
                                                        const Icon(
                                                  Icons.drive_eta,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
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
