import 'dart:convert';
import 'package:driving_quiz_app/models/question_model.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Import your model file here

class QuizScreen extends StatefulWidget {
  final int levelId;

  const QuizScreen({Key? key, required this.levelId}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final baseUrl = APIService.getBaseUrl();
  List<QuestionModel> questions = [];
  bool _isLoading = true;
  int currentIndex = 0;
  int? selectedOptionId;
  bool isAnswerChecked = false;
  String currentLocale = "ar";

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl//levels/${widget.levelId}/questions'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List? ?? [];
        setState(() {
          questions = list.map((e) => QuestionModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
}
