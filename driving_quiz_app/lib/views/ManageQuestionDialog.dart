import 'package:flutter/material.dart';

import 'package:driving_quiz_app/models/question_model.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/services/QuestionService.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/ImageLibraryPicker.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';

enum FormLocale { en, ar }

extension FormLocaleX on FormLocale {
  String get code => this == FormLocale.en ? 'en' : 'ar';
  String get label => this == FormLocale.en ? 'English' : 'العربية';
  TextDirection get direction =>
      this == FormLocale.ar ? TextDirection.rtl : TextDirection.ltr;
}

class ManageQuestionDialog extends StatefulWidget {
  final String levelId;
  final Map<String, dynamic>? question;
  final VoidCallback? onQuestionSaved;

  const ManageQuestionDialog({
    super.key,
    required this.levelId,
    this.question,
    this.onQuestionSaved,
  });

  @override
  State<ManageQuestionDialog> createState() => _ManageQuestionDialogState();
}

class _ManageQuestionDialogState extends State<ManageQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final QuestionService _questionService = QuestionService();

  static const List<String> _identifiers = ['A', 'B', 'C', 'D'];

  late final TextEditingController _orderController;
  late final TextEditingController _questionImageController;

  final Map<FormLocale, TextEditingController> _questionControllers = {
    FormLocale.en: TextEditingController(),
    FormLocale.ar: TextEditingController(),
  };

  late final List<Map<FormLocale, TextEditingController>> _optionControllers;
  late final List<TextEditingController> _optionImageControllers;

  final Set<FormLocale> _selectedLocales = {FormLocale.en, FormLocale.ar};
  FormLocale _activeLocale = FormLocale.en;

  int _correctOptionIndex = 0;
  bool _isSubmitting = false;

  bool get _isEditing => widget.question != null;
  String get _baseUrl => APIService.getBaseUrl();

  @override
  void initState() {
    super.initState();

    _orderController = TextEditingController(
      text: widget.question?['order']?.toString() ?? '',
    );
    _questionImageController = TextEditingController(
      text: widget.question?['image_url']?.toString() ?? '',
    );

    _optionControllers = List.generate(
      4,
      (_) => {
        FormLocale.en: TextEditingController(),
        FormLocale.ar: TextEditingController(),
      },
    );

    _optionImageControllers = List.generate(4, (_) => TextEditingController());

    if (_isEditing) {
      _populateForEdit(widget.question!);
    }
  }

  String _normalizeLocale(dynamic value) {
    final locale = value?.toString().trim().toLowerCase() ?? '';
    if (locale == '0') return 'ar';
    if (locale == '1') return 'en';
    return locale;
  }

  Map<String, String> _readTranslations(dynamic raw) {
    final result = <String, String>{'en': '', 'ar': ''};

    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final locale = _normalizeLocale(item['locale']);
        if (result.containsKey(locale)) {
          result[locale] = item['text']?.toString() ?? '';
        }
      }
    } else if (raw is Map) {
      for (final locale in ['en', 'ar']) {
        final value = raw[locale];
        if (value is Map) {
          result[locale] = value['text']?.toString() ?? '';
        } else if (value != null) {
          result[locale] = value.toString();
        }
      }
    }

    return result;
  }

  bool _isTrue(dynamic value) =>
      value == true || value == 1 || value?.toString() == '1';

  void _populateForEdit(Map<String, dynamic> data) {
    final questionTranslations = _readTranslations(
      data['all_question_translations'] ?? data['translations'],
    );
    final legacyQuestionMap = _readTranslations(data['question_text']);

    final englishQuestion = questionTranslations['en']!.isNotEmpty
        ? questionTranslations['en']!
        : (legacyQuestionMap['en']!.isNotEmpty
            ? legacyQuestionMap['en']!
            : data['question']?.toString() ?? '');

    final arabicQuestion = questionTranslations['ar']!.isNotEmpty
        ? questionTranslations['ar']!
        : legacyQuestionMap['ar']!;

    _questionControllers[FormLocale.en]!.text = englishQuestion;
    _questionControllers[FormLocale.ar]!.text = arabicQuestion;

    final options = data['options'];
    if (options is List) {
      for (final rawOption in options) {
        if (rawOption is! Map) continue;

        final identifier =
            rawOption['identifier']?.toString().trim().toUpperCase() ?? '';
        final index = _identifiers.indexOf(identifier);
        if (index < 0) continue;

        if (_isTrue(rawOption['is_correct'])) {
          _correctOptionIndex = index;
        }

        _optionImageControllers[index].text =
            rawOption['image_url']?.toString() ?? '';

        final translations = _readTranslations(
          rawOption['all_option_translations'] ?? rawOption['translations'],
        );

        _optionControllers[index][FormLocale.en]!.text =
            translations['en']!.isNotEmpty
                ? translations['en']!
                : rawOption['text']?.toString() ?? '';
        _optionControllers[index][FormLocale.ar]!.text = translations['ar']!;
      }
    }

    // Select the languages already represented by the question or its options.
    final detected = <FormLocale>{};
    if (englishQuestion.trim().isNotEmpty) detected.add(FormLocale.en);
    if (arabicQuestion.trim().isNotEmpty) detected.add(FormLocale.ar);

    for (final option in _optionControllers) {
      if (option[FormLocale.en]!.text.trim().isNotEmpty) {
        detected.add(FormLocale.en);
      }
      if (option[FormLocale.ar]!.text.trim().isNotEmpty) {
        detected.add(FormLocale.ar);
      }
    }

    _selectedLocales
      ..clear()
      ..addAll(detected.isEmpty ? {FormLocale.en} : detected);
    _activeLocale = _selectedLocales.contains(FormLocale.en)
        ? FormLocale.en
        : FormLocale.ar;
  }

  void _toggleLocale(FormLocale locale, bool selected) {
    if (!selected && _selectedLocales.length == 1) {
      _showMessage(_activeLocale == FormLocale.ar
          ? 'يجب اختيار لغة واحدة على الأقل.'
          : 'Select at least one language.');
      return;
    }

    setState(() {
      if (selected) {
        _selectedLocales.add(locale);
        _activeLocale = locale;
      } else {
        _selectedLocales.remove(locale);
        if (_activeLocale == locale) {
          _activeLocale = _selectedLocales.first;
        }
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateRequiredText(String? value, String locale) {
    if (!_selectedLocales.any((item) => item.code == locale)) return null;
    if (value == null || value.trim().isEmpty) {
      return locale == 'ar' ? 'هذا الحقل مطلوب' : 'This field is required';
    }
    return null;
  }

  bool _validateSelectedTranslations() {
    for (final locale in _selectedLocales) {
      final questionText = _questionControllers[locale]!.text.trim();
      if (questionText.isEmpty) {
        _activeLocale = locale;
        setState(() {});
        _showMessage(locale == FormLocale.ar
            ? 'يرجى إدخال نص السؤال باللغة العربية.'
            : 'Please enter the question in English.');
        return false;
      }

      for (var i = 0; i < 4; i++) {
        if (_optionControllers[i][locale]!.text.trim().isEmpty) {
          _activeLocale = locale;
          setState(() {});
          _showMessage(locale == FormLocale.ar
              ? 'يرجى إدخال جميع الخيارات باللغة العربية.'
              : 'Please enter all four options in English.');
          return false;
        }
      }
    }
    return true;
  }

  List<QuestionTranslation> _buildQuestionTranslations() {
    return _selectedLocales
        .map(
          (locale) => QuestionTranslation(
            locale: locale.code,
            text: _questionControllers[locale]!.text.trim(),
          ),
        )
        .where((translation) => translation.text.isNotEmpty)
        .toList();
  }

  List<OptionTranslation> _buildOptionTranslations(int index) {
    return _selectedLocales
        .map(
          (locale) => OptionTranslation(
            locale: locale.code,
            text: _optionControllers[index][locale]!.text.trim(),
          ),
        )
        .where((translation) => translation.text.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (_selectedLocales.isEmpty) {
      _showMessage('Select at least one language.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_validateSelectedTranslations()) return;

    final questionId = widget.question?['id']?.toString();
    if (_isEditing && (questionId == null || questionId.isEmpty)) {
      _showMessage('Cannot update this question: its ID is missing.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final model = QuestionModel(
        id: _isEditing ? questionId : null,
        levelId: widget.levelId,
        imageUrl: _questionImageController.text.trim().isEmpty
            ? null
            : _questionImageController.text.trim(),
        translations: _buildQuestionTranslations(),
        options: List.generate(
          4,
          (index) => OptionModel(
            identifier: _identifiers[index],
            isCorrect: index == _correctOptionIndex,
            imageUrl: _optionImageControllers[index].text.trim().isEmpty
                ? null
                : _optionImageControllers[index].text.trim(),
            translations: _buildOptionTranslations(index),
          ),
        ),
      );

      final payload = model.toJson();

      final Map<String, dynamic>? response = _isEditing
          ? await _questionService.updateQuestion(questionId!, payload)
          : await _questionService.createQuestion(payload);

      if (!mounted) return;

      if (response == null || response['status'] != true) {
        final message = response?['message']?.toString();
        _showMessage(message?.isNotEmpty == true
            ? message!
            : (_isEditing
                ? 'Failed to update question.'
                : 'Failed to create question.'));
        return;
      }

      widget.onQuestionSaved?.call();
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Question save error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showMessage('Error saving question: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectImage(TextEditingController controller) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ImageLibraryDialog(
        onImageSelected: (selectedUrl) {
          controller.text = selectedUrl;
          setState(() {});
        },
      ),
    );
  }

  String _imagePreviewUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '$_baseUrl${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageField({
    required String label,
    required TextEditingController controller,
  }) {
    final url = _imagePreviewUrl(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Choose from image library',
                  onPressed: () => _selectImage(controller),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear image',
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (url.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 110,
              width: 140,
              color: AppColors.background,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _languageSettings() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question languages / لغات السؤال',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('English'),
                selected: _selectedLocales.contains(FormLocale.en),
                onSelected: (value) => _toggleLocale(FormLocale.en, value),
              ),
              FilterChip(
                label: const Text('العربية'),
                selected: _selectedLocales.contains(FormLocale.ar),
                onSelected: (value) => _toggleLocale(FormLocale.ar, value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<FormLocale>(
            segments: const [
              ButtonSegment(
                value: FormLocale.en,
                label: Text('English'),
              ),
              ButtonSegment(
                value: FormLocale.ar,
                label: Text('العربية'),
              ),
            ],
            selected: {_activeLocale},
            onSelectionChanged: (selection) {
              setState(() => _activeLocale = selection.first);
            },
          ),
          const SizedBox(height: 6),
          Text(
            _activeLocale == FormLocale.ar
                ? 'أدخل السؤال والخيارات باللغة العربية.'
                : 'Enter the question and options in English.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _translationFields() {
    final locale = _activeLocale;
    final isArabic = locale == FormLocale.ar;

    return Directionality(
      textDirection: locale.direction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _questionControllers[locale],
            minLines: 2,
            maxLines: 4,
            textDirection: locale.direction,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              labelText: isArabic ? 'نص السؤال' : 'Question text',
              hintText: isArabic
                  ? 'اكتب السؤال باللغة العربية'
                  : 'Write the question in English',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) {
            final controller = _optionControllers[index][locale]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _identifiers[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      textDirection: locale.direction,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'الخيار ${_identifiers[index]}'
                            : 'Option ${_identifiers[index]}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: isArabic ? 'صورة الخيار' : 'Option image',
                    onPressed: () =>
                        _selectImage(_optionImageControllers[index]),
                    icon: const Icon(
                      Icons.image_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionImageController.dispose();

    for (final controller in _questionControllers.values) {
      controller.dispose();
    }
    for (final option in _optionControllers) {
      for (final controller in option.values) {
        controller.dispose();
      }
    }
    for (final controller in _optionImageControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = BreakPoint.isDesktop(MediaQuery.of(context).size.width) ||
        BreakPoint.isTablet(MediaQuery.of(context).size.width);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const CustomResponsiveNavbar(),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.deepForest,
          elevation: 1,
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 28 : 14,
                  20,
                  isWide ? 28 : 14,
                  MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: Card(
                  color: AppColors.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 24 : 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.edit_note_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: AppColors.primaryGreen,
                                size: 27,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Edit Question' : 'Add Question',
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _languageSettings(),
                          const SizedBox(height: 22),
                          _sectionTitle(
                            _activeLocale == FormLocale.ar
                                ? 'معلومات السؤال'
                                : 'Question details',
                            Icons.help_outline,
                          ),
                          const SizedBox(height: 14),
                          _imageField(
                            label: _activeLocale == FormLocale.ar
                                ? 'رابط صورة السؤال (اختياري)'
                                : 'Question image URL (optional)',
                            controller: _questionImageController,
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle(
                            _activeLocale == FormLocale.ar
                                ? 'نص السؤال والخيارات'
                                : 'Question and answers',
                            Icons.list_alt,
                          ),
                          _translationFields(),
                          const SizedBox(height: 10),
                          _sectionTitle(
                            _activeLocale == FormLocale.ar
                                ? 'الإجابة الصحيحة'
                                : 'Correct answer',
                            Icons.check_circle_outline,
                          ),
                          ...List.generate(
                            4,
                            (index) => RadioListTile<int>(
                              value: index,
                              groupValue: _correctOptionIndex,
                              activeColor: AppColors.primaryGreen,
                              title: Text(
                                '${_identifiers[index]} — ${_optionControllers[index][_activeLocale]!.text}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _correctOptionIndex = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(false),
                                  child: Text(
                                    _activeLocale == FormLocale.ar
                                        ? 'إلغاء'
                                        : 'Cancel',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: AppColors.textLight,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _isSubmitting
                                        ? (_activeLocale == FormLocale.ar
                                            ? 'جارٍ الحفظ...'
                                            : 'Saving...')
                                        : (_isEditing
                                            ? (_activeLocale == FormLocale.ar
                                                ? 'حفظ التعديلات'
                                                : 'Save changes')
                                            : (_activeLocale == FormLocale.ar
                                                ? 'إضافة السؤال'
                                                : 'Add question')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
