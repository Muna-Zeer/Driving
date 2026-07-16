import 'package:driving_quiz_app/SupportedLanguages.dart';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/CustomTextField.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:driving_quiz_app/services/APIService.dart';
import 'dart:convert';
import 'package:driving_quiz_app/services/LevelService.dart';

class ManageLevelScreen extends StatefulWidget {
  final CategoryModel category;
  final Map<String, dynamic>? level;

  const ManageLevelScreen({
    Key? key,
    required this.category,
    this.level,
  }) : super(key: key);
  @override
  State<ManageLevelScreen> createState() => _ManageLevelScreenState();
}

class _ManageLevelScreenState extends State<ManageLevelScreen>
    with SingleTickerProviderStateMixin {
  final baseUrl = APIService.getBaseUrl();
  final _levelNumberController = TextEditingController();
  final _questionsCountController = TextEditingController();
  final _groupKeyController = TextEditingController();
  late TabController _tabController;
  final Map<String, TextEditingController> _nameControllers = {};
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool get _isEditMode => widget.level != null;
  bool _isLoading = false;
  final LevelService _levelAPI = LevelService();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  @override
  void dispose() {
    _levelNumberController.removeListener(_updateGroupKey);
    _nameControllers['ar']?.removeListener(_updateGroupKey);
    _questionsCountController.dispose();
    _groupKeyController.dispose();
    _sortOrderController.dispose();
    _levelNumberController.dispose();
    _tabController.dispose();
    _nameControllers.forEach((key, controller) => controller.dispose);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: supportedLanguages.length, vsync: this);
    _levelNumberController.addListener(_updateGroupKey);

    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';

      String initialName = '';

      if (_isEditMode) {
        _levelNumberController.text =
            widget.level!['level_number']?.toString() ?? '';
        _questionsCountController.text =
            widget.level!['questions_count']?.toString() ?? '';
        _groupKeyController.text = widget.level!['group_key']?.toString() ?? '';
        _isActive = widget.level!['is_active'] ?? true;

        final List<dynamic> translations = widget.level!['translations'] ?? [];
        final existingTranslation = translations.firstWhere(
            (test) => test['locale'] == langCode,
            orElse: () => null);
        initialName = existingTranslation != null
            ? existingTranslation['name'] ?? ''
            : '';
      } else {
        _levelNumberController.text = '';
        _questionsCountController.text = '';
        _groupKeyController.text = '';
        _isActive = true;
        _sortOrderController.text = '1';
      }

      _nameControllers[langCode] = TextEditingController(text: initialName);
    }

    if (_nameControllers['ar'] != null) {
      _nameControllers['ar']!.addListener(_updateGroupKey);
    }

    if (_isEditMode) {
      _sortOrderController.text = widget.level!['order']?.toString() ?? '1';
      _isActive = widget.level!['is_active'] ?? true;
    }
  }

  Future<void> _savedLevel() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> translationsPayload = {};
    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      final String nameText = _nameControllers[langCode]?.text.trim() ?? '';

      if (nameText.isNotEmpty) {
        translationsPayload[langCode] = {
          'name': nameText,
        };
      }
    }

    final Map<String, dynamic> levelPayload = {
      "category_id": _isEditMode
          ? (widget.level!['category_id']?.toString() ??
              widget.category.id.toString())
          : widget.category.id.toString(),
      "level_number": int.tryParse(_levelNumberController.text.trim()) ?? 1,
      "questions_count":
          int.tryParse(_questionsCountController.text.trim()) ?? 0,
      "group_key": _groupKeyController.text.trim().isEmpty
          ? null
          : _groupKeyController.text.trim(),
      "is_active": _isActive ? 1 : 0,
      "order": int.tryParse(_sortOrderController.text.trim()) ?? 1,
      'translations': translationsPayload,
    };

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    try {
      http.Response response;
      final accessToken = await _storage.read(key: 'auth_token');

      if (accessToken == null) {
        throw Exception(
            isArabic ? 'المستخدم غير مصرح له' : "User not authenticated");
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken'
      };

      if (_isEditMode) {
        final String levelId = widget.level!['id'].toString();
        response = await http.put(
          Uri.parse('$baseUrl/level/$levelId'),
          headers: headers,
          body: jsonEncode(levelPayload),
        );
      } else {
        response = await _levelAPI.sendLevelToAPI(levelPayload);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        final decodedResponseBody = jsonDecode(response.body);

        if (_isEditMode && decodedResponseBody['data'] != null) {
          setState(() {
            widget.level!['level_number'] =
                decodedResponseBody['data']['level_number'];
            widget.level!['questions_count'] =
                decodedResponseBody['data']['questions_count'];
            widget.level!['group_key'] =
                decodedResponseBody['data']['group_key'];
            widget.level!['is_active'] =
                decodedResponseBody['data']['is_active'];
            widget.level!['order'] = decodedResponseBody['data']['order'];
            widget.level!['translations'] =
                decodedResponseBody['data']['translations'];
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? (isArabic
                      ? 'تم تحديث المستوى بنجاح'
                      : 'Level updated successfully')
                  : (isArabic
                      ? 'تمت إضافة المستوى بنجاح'
                      : 'Level created successfully'),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;

        final decodedResponse = jsonDecode(response.body);
        String backendErrorMsg = decodedResponse['message'] ??
            (_isEditMode
                ? (isArabic ? 'فشل في تحديث المستوى' : "Failed to update Level")
                : (isArabic
                    ? 'فشل في إضافة المستوى'
                    : "Failed to add new Level"));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(backendErrorMsg),
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

  void _updateGroupKey() {
    final String CategoryName = _nameControllers['ar']?.text.trim() ?? '';
    final String LevelNumber = _levelNumberController.text.trim();

    if (CategoryName.isNotEmpty && LevelNumber.isNotEmpty) {
      final String cleanCategory = CategoryName.replaceAll(RegExp(r'\s+'), '_');
      _groupKeyController.text = '${cleanCategory}_ ${LevelNumber}';
    } else {
      _groupKeyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String categoryName = widget.category.nameAr ?? 'تؤوريا';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const CustomResponsiveNavbar(),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.deepForest,
        elevation: 1,
      ),
      body: SingleChildScrollView(
          child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(Icons.layers,
                            color: AppColors.primaryGreen, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          _isEditMode
                              ? (isArabic
                                  ? 'تعديل مستوى - $categoryName'
                                  : 'Edit Level - $categoryName')
                              : (isArabic
                                  ? 'إضافة مستوى جديد - $categoryName'
                                  : 'Add New Level - $categoryName'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'أسماء المستوى باللغات'
                              : 'Level Translations',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
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
                                        controller: _nameControllers[langCode]!,
                                        labelText: isArabic
                                            ? 'اسم المستوى (${langMap['name']}) *'
                                            : 'Level Name (${langMap['name']}) *',
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? (isArabic
                                                ? 'يرجى إدخال اسم المستوى'
                                                : 'Please enter level name')
                                            : null,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                }).toList())),
                      ]),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'إعدادات المستوى التقنية'
                            : 'Technical Specifications',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700]),
                      ),
                      // const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _levelNumberController,
                              keyboardType: TextInputType.number,

                              labelText:
                                  isArabic ? 'رقم المستوى' : 'Level Number',

                              // const Icon(Icons.format_list_numbered),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _questionsCountController,
                              keyboardType: TextInputType.number,

                              labelText:
                                  isArabic ? 'عدد الأسئلة' : 'Questions Count',

                              // prefixIcon: const Icon(Icons.quiz),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _groupKeyController,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'مفتاح المجموعة (Optional)'
                              : 'Group Key (Optional)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.vpn_key),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: SwitchListTile(
                  title: Text(
                    isArabic ? 'نشط / تفعيل الظهور' : 'Is Active / Publish',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(isArabic
                      ? 'تحكم بظهور المستوى للمستخدمين'
                      : 'Control level visibility'),
                  value: _isActive,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savedLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditMode
                            ? (isArabic ? 'تحديث البيانات' : 'Update Level')
                            : (isArabic
                                ? 'حفظ وإدراج المستوى'
                                : 'Save and Publish'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
