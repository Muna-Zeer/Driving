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
  final _formKey = GlobalKey;
  FormLocale _currentLocale = FormLocale.en;

  late TextEditingController _questionController;

  final Map<FormLocale, TextEditingController> _questionControllers = {
    FormLocale.ar: TextEditingController(),
    FormLocale.en: TextEditingController(),
  };

  int _correctOptionIndex = 0;
  bool _isSubmiting = false;

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

    if (widget.question['options'] != null) {
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

  @override
  Widget build(BuildContext context) {}
}
