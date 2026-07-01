import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomTextField.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:driving_quiz_app/services/APIService.dart';
import 'dart:convert';

class ManageLevelScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final Map<String, dynamic>? level;
  final List<dynamic> supportedLanguages;

  const ManageLevelScreen({
    Key? key,
    required this.category,
    this.level,
    required this.supportedLanguages,
  }) : super(key: key);
  @override
  State<ManageLevelScreen> createState() => _ManageLevelScreenState();
}

class _ManageLevelScreenState extends State<ManageLevelScreen>
    with SingleTickerProviderStateMixin {
  final baseUrl = APIService.getBaseUrl();

  late TabController _tabController;
  final Map<String, TextEditingController> _nameControllers = {};
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool get _isEditMode => widget.level != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.supportedLanguages.length, vsync: this);
    for (var lang in widget.supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
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
    List<Map<String, dynamic>> translationsPayload = [];
    for (var lang in widget.supportedLanguages) {
      final Map<String, dynamic> langMap = lang as Map<String, dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      final String nameText = _nameControllers[langCode]?.text.trim() ?? '';

      translationsPayload.add({'locale': langCode, 'name': nameText});

      final Map<String, dynamic> levelPayload = {
        "category_id": widget.category['id'],
        'translations': translationsPayload,
        'order': int.tryParse(_sortOrderController.text.trim()) ?? 1,
        'is_active': _isActive
      };
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      try {
        http.Response response;

        if (_isEditMode) {
          final String levelId = widget.level!['id'];
          response = await http.put(Uri.parse('$baseUrl/levels/$levelId'),
              body: levelPayload);
        } else {
          response =
              await http.post(Uri.parse('$baseUrl/levels'), body: levelPayload);
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل مستوى' : 'إضافة مستوى جديد'),
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.supportedLanguages
              .map<Widget>((lang) => Tab(text: lang['name_en']))
              .toList(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.supportedLanguages.map<Widget>((lang) {
                  final String langCode = lang['code'];
                  return TextField(
                    controller: _nameControllers[langCode],
                    decoration: InputDecoration(
                        labelText: 'اسم المستوى (${lang['name_en']})'),
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
              onPressed: _savedLevel,
              child: Text(_isEditMode ? 'تحديث' : 'حفظ'),
            )
          ],
        ),
      ),
    );
  }
}
