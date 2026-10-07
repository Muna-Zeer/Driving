import 'dart:convert';
import 'package:driving_quiz_app/models/question_model.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (questions.isEmpty) {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Quiz"),
          ),
          body: const Center(child: Text("No Questions available")));
    }
    final currentQuestion = questions[currentIndex];
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 1,
            title: Text('Level ${widget.levelId}',
                style: const TextStyle(color: AppColors.textPrimary))),
        body: Column(children: [
          Container(
              height: 55,
              color: AppColors.textSecondary,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    bool isSelected = index == currentIndex;
                    return GestureDetector(
                        onTap: () {
                          setState(
                            () {
                              currentIndex = index;
                              selectedOptionId = null;
                              isAnswerChecked = false;
                            },
                          );
                        },
                        child: Container(
                            width: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.grey[600]
                                  : Colors.grey[800],
                              border: Border(
                                  left: BorderSide(color: Colors.grey[700]!)),
                            ),
                            child: Text(
                              '${questions[index].order}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            )));
                  })),
          //Display option area for options
          Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (currentQuestion.imageUrl != null)
                      Container(
                          height: 160,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                  image:
                                      NetworkImage(currentQuestion.imageUrl!),
                                  fit: BoxFit.contain))),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                            '${currentQuestion.order} - ${currentQuestion.getTitle(currentLocale)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var option = entry.value;
                      String optionLetter = ['أ', 'ب', 'ج', 'د'][idx % 4];
                      bool isSelected = selectedOptionId == option.id;
                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey.shade300;
                      if (isAnswerChecked) {
                        if (option.isCorrect) {
                          bgColor = Colors.green.shade100;
                          borderColor = Colors.green;
                        } else if (isSelected && !option.isCorrect) {
                          bgColor = Colors.red.shade100;
                          borderColor = Colors.red;
                        }
                      } else if (isSelected) {
                        bgColor = Colors.blue.shade50;
                        borderColor = Colors.blue;
                      }
                  })
                  ],
                ))
          )
        ]));
  }
}
