import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
import 'package:flutter/material.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameArabicController = TextEditingController();
  final TextEditingController _nameEnglishController = TextEditingController();
  final TextEditingController _imageURLController = TextEditingController();
  final TextEditingController _typeController =
      TextEditingController(text: 'standard');
  final TextEditingController _orderController =
      TextEditingController(text: '0');
  final TextEditingController _badgeArabicController = TextEditingController();
  final TextEditingController _badgeEnglishController = TextEditingController();

  bool _isActive = true;
  @override
  void dispose() {
    _nameArabicController.dispose();
    _nameEnglishController.dispose();
    _badgeArabicController.dispose();
    _badgeEnglishController.dispose();
    _imageURLController.dispose();
    _typeController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submitData() {
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
              title: Text(isArabic ? 'اضافة قسم جديد' : 'Create new Category'),
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
                          CustomTextField(
                            controller: _typeController,
                            labelText:
                                isArabic ? 'نوع القسم (Type)' : 'Category Type',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
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
                                title: const Text('حالة التفعيل (Is Active)'),
                                subtitle: const Text(
                                    'تحديد ما إذا كان القسم سيظهر للمستخدمين مباشرة أم لا'),
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
                            child: const Text(
                              'حفظ وإدراج القسم',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]))))));
  }
}
