import 'package:driving_quiz_app/services/QuestionService.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
import 'package:flutter/material.dart';

class ManageQuestionDialog extends StatefulWidget {
  final String levelId;
  final Map<String, dynamic>? question;

  const ManageQuestionDialog({Key? key, required this.levelId, this.question})
      : super(key: key);

  @override
  State<ManageQuestionDialog> createState() => _ManageQuestionDialogState();
}

enum FormLocale { ar, en }

class _ManageQuestionDialogState extends State<ManageQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  FormLocale _activeLocale = FormLocale.en;
  final QuestionService _questionService = QuestionService();

  late TextEditingController _imageUrlController;
  late TextEditingController _questionController;

  final Map<FormLocale, TextEditingController> _questionControllers = {
    FormLocale.ar: TextEditingController(),
    FormLocale.en: TextEditingController(),
  };

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
    return Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_isEditing ? 'Edit Question' : 'Add Question',
                          style: Theme.of(context).textTheme.titleLarge)
                    ],
                  ),
                  SegmentedButton<FormLocale>(
                      segments: const [
                        ButtonSegment(
                            value: FormLocale.en, label: Text('English')),
                        ButtonSegment(
                            value: FormLocale.ar, label: Text('Arabic')),
                      ],
                      selected: {
                        _activeLocale
                      },
                      onSelectionChanged: (Set<FormLocale> selection) {
                        setState(() => _activeLocale = selection.first);
                      }),
                  CustomTextField(
                    controller: _imageUrlController,
                    labelText: _activeLocale == FormLocale.en
                        ? 'Image URL (Optional)'
                        : 'رابط الصورة (اختياري)',
                  ),
                  const SizedBox(height: 12),
                  // Question Text Field
                  TextFormField(
                    controller: _questionControllers[_activeLocale],
                    textDirection: _activeLocale == FormLocale.ar
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: _activeLocale == FormLocale.ar
                          ? 'نص السؤال (بالعربية)'
                          : 'Question Text (EN)',
                      border: const OutlineInputBorder(),
                    ),
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
                      _activeLocale == FormLocale.ar ? 'الخيارات:' : 'Options:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Options Cards List
                  ...List.generate(4, (index) {
                    final isCorrect = _correctOptionIndex == index;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              textDirection: _activeLocale == FormLocale.ar
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _correctOptionIndex,
                                  onChanged: (val) => setState(
                                      () => _correctOptionIndex = val!),
                                ),
                                Text(
                                  _activeLocale == FormLocale.ar
                                      ? 'الخيار ${_identifiers[index]} (${isCorrect ? "صحيح" : "غير صحيح"})'
                                      : 'Option ${_identifiers[index]} (${isCorrect ? "Correct" : "Incorrect"})',
                                  style: TextStyle(
                                    fontWeight: isCorrect
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCorrect ? Colors.green : null,
                                  ),
                                ),
                              ],
                            ),
                            TextFormField(
                              controller: _optionControllers[index]
                                  [_activeLocale],
                              textDirection: _activeLocale == FormLocale.ar
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: _activeLocale == FormLocale.ar
                                    ? 'الخيار ${_identifiers[index]} (بالعربية)'
                                    : 'Option ${_identifiers[index]} (EN)',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return _activeLocale == FormLocale.ar
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : Text(
                              _isEditing
                                  ? (_activeLocale == FormLocale.ar
                                      ? 'تحديث السؤال'
                                      : 'Update Question')
                                  : (_activeLocale == FormLocale.ar
                                      ? 'حفظ السؤال'
                                      : 'Save Question'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ));
  }
}
