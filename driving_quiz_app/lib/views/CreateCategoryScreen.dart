import 'package:driving_quiz_app/SupportedLanguages.dart';
import 'package:driving_quiz_app/typeWidget.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
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

  void _submitData() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
    return; 
  }
  
    final Map<String, dynamic> newCategoryPayload = {
      "name_ar": _nameArabicController.text.trim(),
      "name_en": _nameEnglishController.text.trim(),
      "badge_ar": _badgeArabicController.text.trim().isEmpty
          ? null
          : _badgeArabicController.text.trim(),
      "badge_en": _badgeEnglishController.text.trim().isEmpty
          ? null
          : _badgeEnglishController.text.trim(),
      "image_url":
          _imageURLController.text.isEmpty ? null : _imageURLController.text,
      "type": _typeController.text,
      "order": int.tryParse(_orderController.text) ?? 0,
      "is_active": _isActive
    };
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic
            ? 'تمت إضافة الفئة بنجاح'
            : 'Category created successfully'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            appBar: AppBar(
              title: const CustomResponsiveNavbar(),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.deepForest,
              elevation: 1,
            ),
            body: Center(
                child: Container(
                    constraints: const BoxConstraints(maxHeight: 600),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                        key: _formKey,
                        child: ListView(children: [
                          CustomTextField(
                            controller: _nameArabicController,
                            labelText: isArabic
                                ? '(بالعربية)اسم القسم*'
                                : 'Name of Category',
                            validator: (value) => value == null ||
                                    value.trim().isEmpty
                                ? (isArabic
                                    ? 'يرجى إدخال اسم القسم'
                                    : 'Please Enter the value of category name')
                                : null,
                          ),
                          CustomTextField(
                            controller: _nameEnglishController,
                            labelText: isArabic
                                ? 'اسم القسم (بالإنجليزية)*'
                                : 'Category Name (English)*',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? (isArabic
                                        ? 'يرجى إدخال اسم القسم بالإنجليزية'
                                        : 'Please enter English category name')
                                    : null,
                          ),
                          const Divider(),
                          Text(
                            isArabic
                                ? 'نص الشارة العلوية المتغيرة (اختياري)'
                                : 'Upper Badge Text (Optional)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepForest),
                          ),
                          const Divider(),
                          CustomTextField(
                            controller: _badgeArabicController,
                            labelText: isArabic
                                ? 'نص الشارة (بالعربية) - مثل: استكمالي'
                                : 'Badge Text (Arabic) - e.g., Supplementary',
                          ),
                          CustomTextField(
                            controller: _badgeEnglishController,
                            labelText: isArabic
                                ? 'نص الشارة (بالإنجليزية)'
                                : 'Badge Text (English)',
                          ),
                          Text(
                              isArabic
                                  ? 'الإعدادات العامة للقسم'
                                  : 'General Sitting',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepForest)),
                          const Divider(),
                          CustomTextField(
                            controller: _imageURLController,
                            labelText: isArabic
                                ? 'رابط الصورة (Image URL)'
                                : 'Image Url',
                            hintText: 'https://example.com/image.png',
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
                            onPressed: _submitData,
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
