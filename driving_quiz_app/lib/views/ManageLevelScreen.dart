import 'package:driving_quiz_app/SupportedLanguages.dart';
import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:driving_quiz_app/services/APIService.dart';
import 'dart:convert';

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
  List<dynamic> _levels = [];

  @override
  void dispose() {
    _questionsCountController.dispose();
    _groupKeyController.dispose();
    _sortOrderController.dispose();
    _levelNumberController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: supportedLanguages.length, vsync: this);

    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      _nameControllers[langCode] = TextEditingController();

      String initialName = '';

      if (_isEditMode) {
        final List<dynamic> translations = widget.level!['translations'] ?? [];
        final existingTranslation = translations.firstWhere(
            (test) => test['locale'] == langCode,
            orElse: () => null);
        initialName = existingTranslation != null
            ? existingTranslation['name'] ?? ''
            : '';
      }
      _nameControllers[langCode] = TextEditingController(text: initialName);
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
    List<Map<String, dynamic>> translationsPayload = [];
    for (var lang in supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      final String nameText = _nameControllers[langCode]?.text.trim() ?? '';

      translationsPayload.add({'locale': langCode, 'name': nameText});
    }
    final Map<String, dynamic> levelPayload = {
      "category_id": widget.category.id,
      'translations': translationsPayload,
      'order': int.tryParse(_sortOrderController.text.trim()) ?? 1,
      'is_active': _isActive
    };
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      http.Response response;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (_isEditMode) {
        final String levelId = widget.level!['id'].toString();
        response = await http.put(Uri.parse('$baseUrl/levels/$levelId'),
            headers: headers, body: jsonEncode(levelPayload));
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/levels'),
          headers: headers,
          body: jsonEncode(levelPayload),
        );
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        final decodedResponse = jsonDecode(response.body);
        String BackendErrorMsg = decodedResponse['message'] ??
            (isArabic ? 'فشل في إضافة المستوى' : "Failed to add new Level");
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
    final String categoryName = widget.category.nameAr ?? 'تؤوريا';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: const CustomResponsiveNavbar(),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.deepForest,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: supportedLanguages.map<Widget>((lang) {
                  final Map<String, dynamic> langMap =
                      lang as Map<String, dynamic>;
                  final String langCode = langMap['code']?.toString() ?? 'en';

                  final String fieldLabel =
                      langMap['name'] ?? langCode.toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextField(
                      controller: _nameControllers[langCode],
                      decoration: InputDecoration(
                        labelText: 'اسم المستوى ($fieldLabel)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            TextField(
              controller: _sortOrderController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'ترتيب العرض (Order)'),
            ),
            SwitchListTile(
              title: const Text('نشط / Active'),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _savedLevel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isArabic ? 'حفظ وإدراج القسم' : 'Save and Publish',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
