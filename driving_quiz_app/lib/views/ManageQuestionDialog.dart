import 'package:driving_quiz_app/models/question_model.dart';
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
  final VoidCallback? onQuestionSaved;

  const ManageQuestionDialog({
    Key? key,
    required this.levelId,
    this.question,
    this.onQuestionSaved,
  }) : super(key: key);

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
  final TextEditingController _orderController = TextEditingController();
  late List<TextEditingController> _optionImageControllers;
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

    _isEditing = widget.question != null;
    _optionImageControllers = List.generate(4, (_) => TextEditingController());

    _imageUrlController = TextEditingController(
      text: widget.question?['image_url']?.toString() ?? '',
    );

    _imageUrlController.addListener(_onImageUrlChanged);

    if (_isEditing) {
      _populateFormForEdit();
    }
  }

  void _onImageUrlChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _normalizeLocale(dynamic locale) {
    return locale?.toString().toLowerCase() ?? '';
  }

  bool _isTrue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  void _populateFormForEdit() {
    final questionData = widget.question;
    if (questionData == null) return;

    if (questionData['order'] != null) {
      _orderController.text = questionData['order'].toString();
    }
    if (questionData['image_url'] != null) {
      _imageUrlController.text = questionData['image_url'].toString();
    }

    final qTranslations = questionData['translations'] as List? ?? [];
    for (var t in qTranslations) {
      if (t['locale'] == 'en') {
        _questionControllers[FormLocale.en]!.text = t['text']?.toString() ?? '';
      } else if (t['locale'] == 'ar') {
        _questionControllers[FormLocale.ar]!.text = t['text']?.toString() ?? '';
      }
    }

    if (_questionControllers[FormLocale.en]!.text.isEmpty &&
        questionData['question_text'] is Map) {
      final qMap = questionData['question_text'] as Map;
      _questionControllers[FormLocale.en]!.text = qMap['en']?.toString() ?? '';
      _questionControllers[FormLocale.ar]!.text = qMap['ar']?.toString() ?? '';
    }

    if (questionData['options'] != null) {
      final options = questionData['options'] as List;

      // Iterate by index to safely match options even if backend identifiers differ
      for (int i = 0; i < options.length && i < 4; i++) {
        final opt = options[i];
        final identifier = opt['identifier']?.toString();

        int index = _identifiers.indexOf(identifier ?? '');
        if (index == -1) {
          index =
              i; // Fallback to list position index if identifier string doesn't match
        }

        if (index >= 0 && index < 4) {
          // Check if this option is correct
          if (opt['is_correct'] == true ||
              opt['is_correct'] == 1 ||
              opt['is_correct'] == '1') {
            setState(() {
              _correctOptionIndex = index;
            });
          }

          // Populate option image if available
          if (opt['image_url'] != null &&
              _optionImageControllers.length > index) {
            _optionImageControllers[index].text = opt['image_url'].toString();
          }

          // Get option translations list
          final optTranslations = (opt['translations'] ??
                  opt['all_option_translations']) as List? ??
              [];

          for (var ot in optTranslations) {
            if (ot['locale'] == 'en') {
              _optionControllers[index][FormLocale.en]!.text =
                  ot['text']?.toString() ?? '';
            } else if (ot['locale'] == 'ar') {
              _optionControllers[index][FormLocale.ar]!.text =
                  ot['text']?.toString() ?? '';
            }
          }
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final orderText = _orderController.text.trim();
    final order = int.tryParse(_orderController.text.trim()) ?? 1;
    if (order == null || order < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid question order.'),
        ),
      );
      return;
    }

    if (_isEditing &&
        (widget.question?['id'] == null ||
            widget.question!['id'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update this question: its ID is missing.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final questionModel = QuestionModel(
        levelId: widget.levelId,
        order: order,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        translations: [
          QuestionTranslation(
            locale: 'en',
            text: _questionControllers[FormLocale.en]!.text.trim(),
          ),
          QuestionTranslation(
            locale: 'ar',
            text: _questionControllers[FormLocale.ar]!.text.trim(),
          ),
        ],
        options: List.generate(4, (i) {
          return OptionModel(
            identifier: _identifiers[i],
            isCorrect: i == _correctOptionIndex,
            translations: [
              OptionTranslation(
                locale: 'en',
                text: _optionControllers[i][FormLocale.en]!.text.trim(),
              ),
              OptionTranslation(
                locale: 'ar',
                text: _optionControllers[i][FormLocale.ar]!.text.trim(),
              ),
            ],
          );
        }),
      );

      final payload = questionModel.toJson();

      final bool success = _isEditing
          ? await _questionService.updateQuestion(
              widget.question!['id'].toString(),
              payload,
            )
          : await _questionService.createQuestion(payload);

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Failed to update question.'
                  : 'Failed to create question.',
            ),
          ),
        );
        return;
      }
      widget.onQuestionSaved?.call();

      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      debugPrint('Error saving question: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving question: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_onImageUrlChanged);
    _imageUrlController.dispose();
    _orderController.dispose();

    for (var controller in _optionImageControllers) {
      controller.dispose();
    }
    for (final controller in _questionControllers.values) {
      controller.dispose();
    }

    for (final option in _optionControllers) {
      for (final controller in option.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 24,
                            top: 24,
                            left: isWideScreen ? 32 : 16,
                            right: isWideScreen ? 32 : 16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                                child: Card(
                              elevation: 2,
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Centered Header with Icon & Dynamic Title
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isEditing
                                              ? Icons.edit_note_rounded
                                              : Icons
                                                  .add_circle_outline_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isEditing
                                              ? 'Edit Question'
                                              : 'Add Question',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryGreen,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Language Selector (Centered SegmentedButton)
                                    Center(
                                      child: SegmentedButton<FormLocale>(
                                        segments: const [
                                          ButtonSegment(
                                            value: FormLocale.en,
                                            label: Text('English'),
                                          ),
                                          ButtonSegment(
                                            value: FormLocale.ar,
                                            label: Text('Arabic'),
                                          ),
                                        ],
                                        selected: {_activeLocale},
                                        onSelectionChanged:
                                            (Set<FormLocale> selection) {
                                          setState(() =>
                                              _activeLocale = selection.first);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
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

                                        if (_imageUrlController
                                            .text.isNotEmpty) ...[
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.red),
                                            tooltip:
                                                _activeLocale == FormLocale.en
                                                    ? 'Remove Image'
                                                    : 'إزالة الصورة',
                                            onPressed: () {
                                              setState(() {
                                                _imageUrlController.clear();
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                        ],

                                        // Library Picker Button
                                        IconButton.filledTonal(
                                          icon: const Icon(Icons.photo_library,
                                              color: AppColors.primaryGreen),
                                          tooltip:
                                              _activeLocale == FormLocale.en
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

                                    if (_imageUrlController
                                        .text.isNotEmpty) ...[
                                      Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.border),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                      textDirection:
                                          _activeLocale == FormLocale.ar
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
                                      final hasOptionImage =
                                          _optionImageControllers[index]!
                                              .text
                                              .isNotEmpty;

                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                textDirection: _activeLocale ==
                                                        FormLocale.ar
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                                children: [
                                                  Radio<int>(
                                                    value: index,
                                                    groupValue:
                                                        _correctOptionIndex,
                                                    onChanged: (val) =>
                                                        setState(() =>
                                                            _correctOptionIndex =
                                                                val!),
                                                  ),
                                                  Text(
                                                    _activeLocale ==
                                                            FormLocale.ar
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
                                                textDirection: _activeLocale ==
                                                        FormLocale.ar
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
                                              const SizedBox(height: 12),
                                              // Option Image URL Field & Library Picker Button Row
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _optionImageControllers[
                                                              index],
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: _activeLocale ==
                                                                FormLocale.en
                                                            ? 'Option ${_identifiers[index]}: Image Url (Optional)'
                                                            : 'رابط الصورة للخيار ${_identifiers[index]} (اختياري)',
                                                        prefixIcon: const Icon(
                                                            Icons
                                                                .image_outlined,
                                                            size: 20),
                                                        border:
                                                            const OutlineInputBorder(),
                                                        isDense: true,
                                                      ),
                                                      onChanged: (val) =>
                                                          setState(() {}),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // Library Picker Button
                                                  IconButton.filledTonal(
                                                    icon: const Icon(
                                                        Icons.photo_library,
                                                        color: AppColors
                                                            .primaryGreen,
                                                        size: 20),
                                                    tooltip: _activeLocale ==
                                                            FormLocale.en
                                                        ? 'Select from Library'
                                                        : 'اختر من المكتبة',
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            ImageLibraryDialog(
                                                          onImageSelected:
                                                              (String
                                                                  selectedUrl) {
                                                            setState(() {
                                                              _optionImageControllers[
                                                                          index]
                                                                      .text =
                                                                  selectedUrl;
                                                            });
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                  // Clear Button (Shown only if text is not empty)
                                                  if (_optionImageControllers[
                                                          index]
                                                      .text
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 4),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.clear,
                                                          color: Colors.red,
                                                          size: 20),
                                                      tooltip: _activeLocale ==
                                                              FormLocale.en
                                                          ? 'Remove Image'
                                                          : 'إزالة الصورة',
                                                      onPressed: () {
                                                        setState(() {
                                                          _optionImageControllers[
                                                                  index]
                                                              .clear();
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ],
                                              ),

// Thumbnail Preview (Shown below input if URL is present)
                                              if (_optionImageControllers[index]
                                                  .text
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Container(
                                                    height: 80,
                                                    width: 80,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                    child: Image.network(
                                                      _optionImageControllers[
                                                              index]
                                                          .text
                                                          .trim(),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Center(
                                                        child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                            borderRadius:
                                                BorderRadius.circular(8)),
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
                                                  ? (_activeLocale ==
                                                          FormLocale.ar
                                                      ? 'تحديث السؤال'
                                                      : 'Update Question')
                                                  : (_activeLocale ==
                                                          FormLocale.ar
                                                      ? 'حفظ وإدراج السؤال'
                                                      : 'Save and Publish'),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            )),
                          ))));
            })));
  }
}
