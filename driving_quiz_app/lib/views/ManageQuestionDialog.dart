import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/widgets/ImageLibraryPicker.dart';
import 'package:flutter/material.dart';
import 'package:driving_quiz_app/services/QuestionService.dart';
import 'package:driving_quiz_app/views/CategoriesScreen.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/CustomTextField.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';

class ManageQuestionDialog extends StatefulWidget {
  final String levelId;
  final Map<String, dynamic>? question;

  const ManageQuestionDialog({Key? key, required this.levelId, this.question})
      : super(key: key);

  @override
  State<ManageQuestionDialog> createState() => _ManageQuestionDialogState();
}

enum FormLocale { ar, en }

final baseUrl = APIService.getBaseUrl();

class _ManageQuestionDialogState extends State<ManageQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  FormLocale _activeLocale = FormLocale.en;
  final QuestionService _questionService = QuestionService();

  late TextEditingController _imageUrlController;

  final Map<FormLocale, TextEditingController> _questionControllers = {
    FormLocale.ar: TextEditingController(),
    FormLocale.en: TextEditingController(),
  };

  bool _isLoading = false;
  int _correctOptionIndex = 0;
  bool _isSubmitting = false;
  late bool _isEditing;
  final List<Map<FormLocale, TextEditingController>> _optionControllers =
      List.generate(
          4,
          (_) => {
                FormLocale.en: TextEditingController(),
                FormLocale.ar: TextEditingController(),
              });
  final List<String> _identifiers = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.question != null; // Detect Edit Mode
    _imageUrlController =
        TextEditingController(text: widget.question?['image_url'] ?? '');

    if (_isEditing) {
      _populateFormForEdit();
    }
    _imageUrlController.addListener(() {
      setState(() => {});
    });
  }

  void _populateFormForEdit() {
    final qTranslations = widget.question?['translations'] ?? [];
    _questionControllers[FormLocale.en]!.text = qTranslations
            .firstWhere((t) => t['locale'] == 'en', orElse: () => {})['text'] ??
        '';
    _questionControllers[FormLocale.ar]!.text = qTranslations
            .firstWhere((t) => t['locale'] == 'ar', orElse: () => {})['text'] ??
        '';

    if (widget.question?['options'] != null) {
      final options = widget.question!['options'] as List;
      for (int i = 0; i < options.length && i < 4; i++) {
        if (options[i]['is_correct'] == true || options[i]['is_correct'] == 1) {
          _correctOptionIndex = i;
        }

        final optTranslations = options[i]['translations'] as List ?? [];
        _optionControllers[i][FormLocale.en]!.text = optTranslations.firstWhere(
                (t) => t['locale'] == 'en',
                orElse: () => {})['text'] ??
            '';
        _optionControllers[i][FormLocale.ar]!.text = optTranslations.firstWhere(
                (t) => t['locale'] == 'ar',
                orElse: () => {})['text'] ??
            '';
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });
    final payload = {
      'level_id': widget.levelId,
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'question_text': {
        'en': _questionControllers[FormLocale.en]!.text.trim(),
        'ar': _questionControllers[FormLocale.ar]!.text.trim(),
      },
      'options': List.generate(4, (i) {
        return {
          'identifier': _identifiers[i],
          'is_correct': i == _correctOptionIndex,
          'translations': {
            'en': _questionControllers[FormLocale.en]!.text.trim(),
            'ar': _questionControllers[FormLocale.ar]!.text.trim(),
          },
        };
      })
    };
    bool success;
    if (_isEditing) {
      success = await _questionService.updateQuestion(
          widget.question!['id'], payload);
    } else {
      success = await _questionService.createQuestion(payload);
    }
    setState(() => _isSubmitting = false);
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: const CustomResponsiveNavbar(),
            endDrawer: MediaQuery.of(context).size.width < BreakPoint.tableMax
                ? buildMobileDrawer()
                : null,
            body: LayoutBuilder(builder: (context, constraints) {
              final isDesktop = BreakPoint.isDesktop(constraints.maxWidth);
              final isTablet = BreakPoint.isTablet(constraints.maxWidth);
              final isWideScreen = isDesktop || isTablet;

              return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: 1000), // Max content width for desktop
                    child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                          top: 24,
                          left: isWideScreen ? 32 : 16,
                          right: isWideScreen ? 32 : 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        _isEditing
                                            ? 'Edit Question'
                                            : 'Add Question',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge)
                                  ],
                                ),
                                SegmentedButton<FormLocale>(
                                    segments: const [
                                      ButtonSegment(
                                          value: FormLocale.en,
                                          label: Text('English')),
                                      ButtonSegment(
                                          value: FormLocale.ar,
                                          label: Text('Arabic')),
                                    ],
                                    selected: {
                                      _activeLocale
                                    },
                                    onSelectionChanged:
                                        (Set<FormLocale> selection) {
                                      setState(() =>
                                          _activeLocale = selection.first);
                                    }),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _imageUrlController,
                                        decoration: InputDecoration(
                                          labelText:
                                              _activeLocale == FormLocale.en
                                                  ? 'Image URL (Optional)'
                                                  : 'رابط الصورة (اختياري)',
                                        ),
                                        onChanged: (val) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Show Clear/Cancel button only if an image is selected/typed
                                    if (_imageUrlController
                                        .text.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.red),
                                        tooltip: _activeLocale == FormLocale.en
                                            ? 'Remove Image'
                                            : 'إزالة الصورة',
                                        onPressed: () {
                                          setState(() {
                                            _imageUrlController
                                                .clear(); // Clears the text field & URL
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                    ],

                                    // Library Picker Button
                                    IconButton.filledTonal(
                                      icon: const Icon(Icons.photo_library,
                                          color: AppColors.primaryGreen),
                                      tooltip: _activeLocale == FormLocale.en
                                          ? 'Select from Library'
                                          : 'اختر من المكتبة',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              ImageLibraryDialog(
                                            onImageSelected:
                                                (String selectedUrl) {
                                              setState(() {
                                                _imageUrlController.text =
                                                    selectedUrl;
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

// Optional: Live preview thumbnail underneath
                                if (_imageUrlController.text.isNotEmpty) ...[
                                  Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrlController.text
                                                .startsWith(baseUrl)
                                            ? _imageUrlController.text
                                            : 'http://127.0.0.1:8000${_imageUrlController.text}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(Icons.broken_image,
                                              color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller:
                                      _questionControllers[_activeLocale]!,
                                  textDirection: _activeLocale == FormLocale.ar
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  labelText: _activeLocale == FormLocale.ar
                                      ? 'نص السؤال (بالعربية)'
                                      : 'Question Text (EN)',
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return _activeLocale == FormLocale.ar
                                          ? 'يرجى إدخال نص السؤال باللغة العربية'
                                          : 'Please enter question text in English';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Options Section Header
                                Align(
                                  alignment: _activeLocale == FormLocale.ar
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    _activeLocale == FormLocale.ar
                                        ? 'الخيارات:'
                                        : 'Options:',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                ...List.generate(4, (index) {
                                  final isCorrect =
                                      _correctOptionIndex == index;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            textDirection:
                                                _activeLocale == FormLocale.ar
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                            children: [
                                              Radio<int>(
                                                value: index,
                                                groupValue: _correctOptionIndex,
                                                onChanged: (val) => setState(
                                                    () => _correctOptionIndex =
                                                        val!),
                                              ),
                                              Text(
                                                _activeLocale == FormLocale.ar
                                                    ? 'الخيار ${_identifiers[index]} (${isCorrect ? "صحيح" : "غير صحيح"})'
                                                    : 'Option ${_identifiers[index]} (${isCorrect ? "Correct" : "Incorrect"})',
                                                style: TextStyle(
                                                  fontWeight: isCorrect
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          CustomTextField(
                                            controller:
                                                _optionControllers[index]
                                                    [_activeLocale]!,
                                            textDirection:
                                                _activeLocale == FormLocale.ar
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                            labelText: _activeLocale ==
                                                    FormLocale.ar
                                                ? 'الخيار ${_identifiers[index]} (بالعربية)'
                                                : 'Option ${_identifiers[index]} (EN)',
                                            validator: (v) {
                                              if (v == null ||
                                                  v.trim().isEmpty) {
                                                return _activeLocale ==
                                                        FormLocale.ar
                                                    ? 'مطلوب'
                                                    : 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                const SizedBox(height: 16),

                                // Submit Button
                                const SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                ),
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 40,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          _isEditing
                                              ? (_activeLocale == FormLocale.ar
                                                  ? 'تحديث السؤال'
                                                  : 'Update Question')
                                              : (_activeLocale == FormLocale.ar
                                                  ? 'حفظ وإدراج السؤال'
                                                  : 'Save and Publish'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        )),
                  ));
            })));
  }
}
