import 'package:flutter/material.dart';
import 'package:driving_quiz_app/services/QuestionService.dart';

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
}

final List<Map<FormLocale, TextEditingController>> _optionControllers =
    List.generate(
        4,
        (_) => {
              FormLocale.en: TextEditingController(),
              FormLocale.ar: TextEditingController(),
            });
final List<String> _identifiers = ['A', 'B', 'C', 'D'];
