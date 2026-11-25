import 'dart:convert';
import 'package:driving_quiz_app/models/question_model.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/services/AdminService.dart';
import 'package:driving_quiz_app/services/QuestionService.dart';
import 'package:driving_quiz_app/views/ManageQuestionDialog.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:driving_quiz_app/widgets/quiz_stats_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final String levelId;

  const QuizScreen({Key? key, required this.levelId}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionService _apiService = QuestionService();
  final baseUrl = APIService.getBaseUrl();
  AdminService _authService = AdminService();
  List<QuestionModel> questions = [];
  bool _isLoading = true;
  bool _isFetching = false;
  bool _refreshRequested = false;
  int currentIndex = 0;
  String? selectedOptionId;
  bool isAnswerChecked = false;

  String currentLocale = "ar";
  bool _isAdmin = false;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int xpPoints = 0;
  int lastXpEarned = 0;
  final Set<int> _countedQuestionIndices = {};
  final Set<String> _answeredQuestionIds = {};
  QuestionModel get currentQuestion => questions[currentIndex];
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  String? attemptUuid;
  bool isSubmittingAnswer = false;
  final Set<String> _answeredQuestions = {};
  final Map<String, String> _savedAnswers = {};
  final Map<String, bool> _answerResults = {};

  int _attemptNumber = 1;
  int _totalAttempts = 3;
  int _remainingAttempts = 2;

  bool _isExamCompleted = false;
  @override
  void initState() {
    super.initState();

    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      // This now resumes an existing attempt when available.
      await startQuizAttempt();

      if (!mounted || attemptUuid == null) return;

      // Load the questions.
      await fetchQuestions();

      if (!mounted) return;

      // Restore previously saved answers and statistics.
      await fetchQuizProgress();
    } catch (e) {
      debugPrint('Quiz initialization error: $e');
    }
  }

  Future<void> _initAdminRole() async {
    await _authService.loadUserRole();
    setState(() {
      _isAdmin = _authService.isAdmin;
    });
  }

  Future<void> fetchQuestions({
    bool showLoading = false,
  }) async {
    // Prevent multiple requests at the same time.
    if (_isFetching) {
      _refreshRequested = true;

      if (showLoading && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      return;
    }

    _isFetching = true;

    try {
      do {
        _refreshRequested = false;

        if (!mounted) {
          return;
        }

        if (showLoading) {
          setState(() {
            _isLoading = true;
          });

          showLoading = false;
        }

        // Save the currently displayed question ID.
        String? previousQuestionId;

        if (questions.isNotEmpty &&
            currentIndex >= 0 &&
            currentIndex < questions.length) {
          previousQuestionId = questions[currentIndex].id;
        }

        // Get authentication token.
        final token = await _storage.read(key: 'auth_token');

        if (token == null || token.isEmpty) {
          debugPrint('Authentication token not found.');
          return;
        }

        // Request questions from Laravel API.
        final response = await http.get(
          Uri.parse(
            '$baseUrl/levels/${widget.levelId}/questions',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (!mounted) {
          return;
        }

        if (response.statusCode != 200) {
          debugPrint(
            'Fetch questions failed: ${response.statusCode}',
          );
          debugPrint(response.body);
          return;
        }

        // Decode response.
        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          debugPrint('Invalid response format.');
          return;
        }

        final rawData = decoded['data'];

        if (rawData is! List) {
          debugPrint('No questions data found.');
          return;
        }

        // Convert API data into QuestionModel.
        final List<QuestionModel> refreshedQuestions = [];

        for (final item in rawData) {
          if (item is Map) {
            refreshedQuestions.add(
              QuestionModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }

        if (!mounted) {
          return;
        }

        // Update questions and restore the current question.
        setState(() {
          questions = refreshedQuestions;

          if (questions.isEmpty) {
            currentIndex = 0;
            selectedOptionId = null;
            isAnswerChecked = false;
          } else {
            // Find the previously displayed question.
            int newIndex = -1;

            if (previousQuestionId != null) {
              newIndex = questions.indexWhere(
                (question) => question.id == previousQuestionId,
              );
            }

            if (newIndex >= 0) {
              currentIndex = newIndex;
            } else if (currentIndex >= questions.length) {
              currentIndex = questions.length - 1;
            } else if (currentIndex < 0) {
              currentIndex = 0;
            }

            // Get current question ID.
            final questionId = questions[currentIndex].id;

            // Restore previously selected answer.
            if (questionId != null) {
              selectedOptionId = _savedAnswers[questionId];

              // Restore answer checked status.
              isAnswerChecked = _answeredQuestionIds.contains(questionId);
            } else {
              selectedOptionId = null;
              isAnswerChecked = false;
            }
          }
        });

        debugPrint('Questions loaded: ${questions.length}');
        debugPrint('Current index: $currentIndex');
        debugPrint('Selected option: $selectedOptionId');

        // Fetch latest attempt statistics.
        if (attemptUuid != null && attemptUuid!.isNotEmpty) {
          await fetchAttemptStats();
        }
      } while (_refreshRequested && mounted);
    } catch (e, stackTrace) {
      debugPrint('Error fetching questions: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isFetching = false;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openQuestionForm({
    QuestionModel? question,
  }) async {
    if (!_isAdmin) return;

    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManageQuestionDialog(
          levelId: widget.levelId,
          question: question?.toJson(),
          key: ValueKey(
            question == null ? 'create-question' : 'edit-${question.id}',
          ),
        ),
      ),
    );

    if (!mounted) return;

    // Refresh ONLY after a successful create/update.
    if (result == true) {
      debugPrint(
        'Question saved successfully. Refreshing QuizScreen...',
      );

      await fetchQuestions();
    }
  }

  void handleDeleteQuestion(BuildContext context, String? hashedId) async {
    try {
      if (hashedId == null || hashedId.isEmpty) {
        print('Error: Question ID is null or empty!');
        return;
      }

      bool isArabic = false;
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = false;
      }

      if (!context.mounted) return;

      bool confirmDelete = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
              content: Text(isArabic
                  ? 'هل أنت متأكد من حذف هذا السؤال نهائياً؟ سيتم إعادة ترتيب باقي الأسئلة تلقائياً.'
                  : 'Are you sure you want to delete this Question?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    isArabic ? 'حذف' : 'Delete',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmDelete) return;

      final success = await _apiService.deleteQuestion(hashedId);

      if (!context.mounted) return;

      if (success) {
        AppAlerts.showAlert(
          context,
          isArabic ? 'تم حذف السؤال بنجاح' : 'Question deleted successfully',
        );

        await fetchQuestions();
      } else {
        AppAlerts.showError(
          context,
          isArabic ? 'فشل في حذف السؤال' : 'Failed to delete Question',
        );
      }
    } catch (e, stackTrace) {
      print('Exception caught in handleDeleteQuestion: $e');
      print(stackTrace);

      if (!context.mounted) return;
      AppAlerts.showError(
        context,
        'Error: $e',
      );
    }
  }

  Future<void> _checkAnswer() async {
    if (selectedOptionId == null ||
        isAnswerChecked ||
        isSubmittingAnswer ||
        attemptUuid == null) {
      return;
    }

    final questionId = currentQuestion.id;

    // Validate encoded question ID
    if (questionId == null || questionId.isEmpty) {
      throw Exception('Invalid question ID');
    }

    // Prevent duplicate submissions
    if (_answeredQuestionIds.contains(questionId)) {
      setState(() {
        isAnswerChecked = true;
      });
      return;
    }

    setState(() {
      isSubmittingAnswer = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final baseUrl = await APIService.getBaseUrl();

      // Send the encoded ID as a String.
      debugPrint('Encoded Question ID: $questionId');
      debugPrint('Selected Option: $selectedOptionId');

      final response = await http.post(
        Uri.parse(
          '$baseUrl/quiz-attempts/$attemptUuid/submit-answer',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question_id': questionId,
          'selected_option': selectedOptionId,
        }),
      );

      debugPrint('Submit Answer Status: ${response.statusCode}');
      debugPrint('Submit Answer Response: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode != 200 || decoded['status'] != true) {
        throw Exception(
          decoded['message'] ?? 'Failed to submit answer.',
        );
      }

      final data = decoded['data'];

      if (!mounted) return;

      setState(() {
        _savedAnswers[questionId] = selectedOptionId!;

        _answerResults[questionId] = data['is_correct'] == true;

        _answeredQuestionIds.add(questionId);

        correctAnswers = data['correct_answers'] ?? 0;
        wrongAnswers = data['wrong_answers'] ?? 0;
        xpPoints = data['xp_points'] ?? 0;

        lastXpEarned =
            data['already_answered'] == true ? 0 : (data['xp_earned'] ?? 0);

        isAnswerChecked = true;
        isSubmittingAnswer = false;
      });
    } catch (e) {
      debugPrint('Submit answer error: $e');

      if (!mounted) return;

      setState(() {
        isSubmittingAnswer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تسجيل الإجابة: $e'),
        ),
      );
    }
  }

  Future<void> startQuizAttempt() async {
    try {
      debugPrint('========== START / RESUME ATTEMPT ==========');

      // 1. Get authentication token
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      // 2. Get API base URL
      final baseUrl = await APIService.getBaseUrl();

      // 3. Send request
      final response = await http.post(
        Uri.parse('$baseUrl/quiz-attempts/start'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'level_id': widget.levelId.toString(),
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      // 4. Decode JSON safely
      final dynamic decodedJson = jsonDecode(response.body);

      if (decodedJson is! Map<String, dynamic>) {
        throw Exception('Invalid server response format.');
      }

      final Map<String, dynamic> decoded = decodedJson;

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to start quiz attempt.',
        );
      }

      if (decoded['status'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Unable to start quiz attempt.',
        );
      }

      // 5. Validate data
      final dynamic rawData = decoded['data'];

      if (rawData is! Map) {
        throw Exception('Attempt data is missing or invalid.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

      final dynamic rawAttemptId = data['attempt_id'];

      if (rawAttemptId == null || rawAttemptId.toString().trim().isEmpty) {
        throw Exception('Attempt UUID was not returned.');
      }

      final String receivedAttemptUuid = rawAttemptId.toString();

      // 6. Convert statistics safely
      int parseNumber(dynamic value) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      final int receivedCorrectAnswers = parseNumber(data['correct_answers']);

      final int receivedWrongAnswers = parseNumber(data['wrong_answers']);

      final int receivedXpPoints = parseNumber(data['xp_points']);

      // 7. Store UUID locally
      await storage.write(
        key: 'active_attempt_uuid_${widget.levelId}',
        value: receivedAttemptUuid,
      );

      // 8. Update screen state
      if (!mounted) return;

      setState(() {
        attemptUuid = receivedAttemptUuid;
        correctAnswers = receivedCorrectAnswers;
        wrongAnswers = receivedWrongAnswers;
        xpPoints = receivedXpPoints;
      });

      debugPrint('Attempt UUID: $attemptUuid');
      debugPrint('Correct Answers: $correctAnswers');
      debugPrint('Wrong Answers: $wrongAnswers');
      debugPrint('XP Points: $xpPoints');

      debugPrint('============================================');
    } catch (e, stackTrace) {
      debugPrint('Start Quiz Attempt Error: $e');
      debugPrint('Stack Trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start quiz: $e'),
        ),
      );
    }
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= questions.length) return;
    if (isSubmittingAnswer) return;

    final questionId = questions[index].id.toString();
    final savedAnswer = _savedAnswers[questionId];

    setState(() {
      currentIndex = index;
      selectedOptionId = savedAnswer;
      isAnswerChecked = _answeredQuestionIds.contains(questionId);
    });

    debugPrint('========== NAVIGATION ==========');
    debugPrint('Index: $index');
    debugPrint('Question ID: $questionId');
    debugPrint('Selected Option: $selectedOptionId');
    debugPrint('Checked: $isAnswerChecked');
    debugPrint('================================');
  }

  void _selectOption(String optionId) {
    if (isAnswerChecked || isSubmittingAnswer) return;

    final questionId = currentQuestion.id.toString();

    if (questionId.isEmpty || attemptUuid == null) return;

    setState(() {
      selectedOptionId = optionId;
      _savedAnswers[questionId] = optionId;
    });

    debugPrint('========== SELECT OPTION ==========');
    debugPrint('Question ID: $questionId');
    debugPrint('Selected Option: $optionId');
    debugPrint('Saved Answers: $_savedAnswers');
    debugPrint('=================================');

    // Save immediately in the database.
    _saveAnswerToDatabase(
      questionId: questionId,
      selectedOption: optionId,
    );
  }

  Future<void> fetchAttemptStats() async {
    if (attemptUuid == null || attemptUuid!.isEmpty) return;

    try {
      final accessToken = await _storage.read(key: 'auth_token');

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Fetch stats: token not found');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/quiz-attempts/$attemptUuid'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('Stats response status: ${response.statusCode}');
      debugPrint('Stats response body: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch attempt statistics');
        return;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded['data'];

      if (data == null || !mounted) return;

      final newCorrect = (data['correct_answers'] as num?)?.toInt() ?? 0;
      final newWrong = (data['wrong_answers'] as num?)?.toInt() ?? 0;
      final newXp = (data['xp_points'] as num?)?.toInt() ?? 0;

      if (!mounted) return;

      setState(() {
        correctAnswers = newCorrect;
        wrongAnswers = newWrong;
        xpPoints = newXp;
      });

      debugPrint('Updated stats:');
      debugPrint('Correct: $correctAnswers');
      debugPrint('Wrong: $wrongAnswers');
      debugPrint('XP: $xpPoints');
    } catch (e, stackTrace) {
      debugPrint('Fetch attempt stats error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> fetchQuizProgress() async {
    if (attemptUuid == null || attemptUuid!.isEmpty) return;

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final baseUrl = await APIService.getBaseUrl();

      final response = await http.get(
        Uri.parse('$baseUrl/quiz-attempts/$attemptUuid/progress'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('========== PROGRESS RESPONSE ==========');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('=======================================');

      final decoded = jsonDecode(response.body);

      if (response.statusCode != 200 || decoded['status'] != true) {
        throw Exception(
          decoded['message'] ?? 'Failed to retrieve quiz progress.',
        );
      }

      final data = decoded['data'];

      if (data == null) {
        throw Exception('Progress data is null.');
      }

      final List<dynamic> answers = data['answers'] as List<dynamic>? ?? [];

      final Map<String, String> restoredAnswers = {};
      final Map<String, bool> restoredResults = {};
      final Set<String> restoredAnsweredIds = {};

      for (final item in answers) {
        final answer = Map<String, dynamic>.from(item);

        final questionId = answer['question_id']?.toString();
        final selectedOption = answer['selected_option']?.toString();

        if (questionId == null ||
            questionId.isEmpty ||
            selectedOption == null ||
            selectedOption.isEmpty) {
          continue;
        }

        restoredAnswers[questionId] = selectedOption;
        restoredAnsweredIds.add(questionId);

        final isCorrect = answer['is_correct'];

        if (isCorrect != null) {
          restoredResults[questionId] =
              isCorrect == true || isCorrect == 1 || isCorrect == '1';
        }
      }

      if (!mounted) return;

      setState(() {
        correctAnswers = (data['correct_answers'] as num?)?.toInt() ?? 0;

        wrongAnswers = (data['wrong_answers'] as num?)?.toInt() ?? 0;

        xpPoints = (data['xp_points'] as num?)?.toInt() ?? 0;

        _savedAnswers
          ..clear()
          ..addAll(restoredAnswers);

        _answerResults
          ..clear()
          ..addAll(restoredResults);

        _answeredQuestionIds
          ..clear()
          ..addAll(restoredAnsweredIds);
      });

      debugPrint('========== RESTORED PROGRESS ==========');
      debugPrint('Correct: $correctAnswers');
      debugPrint('Wrong: $wrongAnswers');
      debugPrint('XP: $xpPoints');
      debugPrint('Saved answers: $_savedAnswers');
      debugPrint('Answer results: $_answerResults');
      debugPrint('Answered IDs: $_answeredQuestionIds');
      debugPrint('=======================================');
    } catch (e, stackTrace) {
      debugPrint('Fetch quiz progress error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _saveAnswerToDatabase({
    required String questionId,
    required String selectedOption,
  }) async {
    if (attemptUuid == null || attemptUuid!.isEmpty) {
      return false;
    }

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        return false;
      }

      final baseUrl = await APIService.getBaseUrl();

      final response = await http.post(
        Uri.parse(
          '$baseUrl/quiz-attempts/$attemptUuid/save-answer',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question_id': questionId,
          'selected_option': selectedOption,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        debugPrint('Answer autosaved successfully: $questionId');
        return true;
      }

      debugPrint('Autosave failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Autosave error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomResponsiveNavbar(),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomResponsiveNavbar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                currentLocale == "ar"
                    ? "لا توجد أسئلة متاحة"
                    : "No Questions available",
                style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    _openQuestionForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سؤال جديد'),
                )
              ]
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomResponsiveNavbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Centered Quiz Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Right side: Admin Actions
                            Expanded(
                              child: Builder(builder: (context) {
                                debugPrint('''
========== QUIZ STATS ==========
Correct Answers: $correctAnswers
Wrong Answers: $wrongAnswers
XP Points: $xpPoints
Last XP Earned: $lastXpEarned
================================
''');
                                return QuizStatsHeader(
                                  correctAnswers: correctAnswers,
                                  wrongAnswers: wrongAnswers,
                                  xpPoints: xpPoints,
                                  lastXpEarned: lastXpEarned,
                                );
                              }),
                            ),
                            if (_isAdmin)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.primaryGreen,
                                      ),
                                      tooltip: 'Edit question',
                                      onPressed: () async {
                                        await _openQuestionForm(
                                          question: currentQuestion,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      tooltip: 'حذف السؤال',
                                      onPressed: () => handleDeleteQuestion(
                                          context, questions[currentIndex].id),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: AppColors.textLight,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        _openQuestionForm();
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        '  إضافة سؤال  ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (currentQuestion.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Image.network(
                                currentQuestion.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.broken_image,
                                      color: AppColors.textSecondary, size: 48),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Question Title
                        Text(
                          currentQuestion.getTitle(currentLocale),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 24),

                        // Options Area
                        ...currentQuestion.options.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var option = entry.value;
                          String optionLetter =
                              idx < currentQuestion.options.length && idx < 4
                                  ? ['A', 'B', 'C', 'D'][idx]
                                  : '${idx + 1}';
                          bool isSelected =
                              selectedOptionId == option.identifier.toString();

                          Color bgColor = AppColors.surface;
                          Color borderColor = AppColors.border;
                          Color textColor = AppColors.textPrimary;

                          if (isAnswerChecked) {
                            if (option.isCorrect) {
                              bgColor = AppColors.success.withOpacity(0.15);
                              borderColor = AppColors.success;
                              textColor = AppColors.success;
                            } else if (isSelected && !option.isCorrect) {
                              bgColor = AppColors.error.withOpacity(0.15);
                              borderColor = AppColors.error;
                              textColor = AppColors.error;
                            }
                          } else if (isSelected) {
                            bgColor = AppColors.primaryGreen.withOpacity(0.1);
                            borderColor = AppColors.primaryGreen;
                          }

                          // 👈 Extract option image url safely from the option model
                          final String optionImageUrl = option.imageUrl ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                _selectOption(option.identifier.toString());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: borderColor, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.getText(currentLocale),
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: textColor,
                                              fontWeight: isSelected ||
                                                      (isAnswerChecked &&
                                                          option.isCorrect)
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),

                                          // 👈 Display option image underneath the text if it exists
                                          if (optionImageUrl.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                optionImageUrl,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.broken_image,
                                                        color: AppColors
                                                            .textSecondary,
                                                        size: 32),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryGreen
                                                : AppColors.background,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border:
                                                Border.all(color: borderColor),
                                          ),
                                          child: Text(
                                            optionLetter,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.textLight
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Action Buttons
                Row(
                  children: [
                    // PREVIOUS
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          disabledBackgroundColor: AppColors.surface,
                          disabledForegroundColor: Colors.grey,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onPressed: currentIndex > 0 && !isSubmittingAnswer
                            ? () => _goToQuestion(currentIndex - 1)
                            : null,
                        child: const Text(
                          'السابق',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
// CHECK ANSWER
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: AppColors.textLight,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: selectedOptionId != null &&
                                !isAnswerChecked &&
                                !isSubmittingAnswer
                            ? _checkAnswer
                            : null,
                        child: isSubmittingAnswer
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'تحقق من الإجابة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // NEXT
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          disabledBackgroundColor: AppColors.surface,
                          disabledForegroundColor: Colors.grey,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onPressed: currentIndex < questions.length - 1 &&
                                !isSubmittingAnswer
                            ? () => _goToQuestion(currentIndex + 1)
                            : null,
                        child: const Text(
                          'التالي',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Wrap(
                    textDirection: TextDirection.ltr,
                    spacing: 5,
                    runSpacing: 5,
                    children: List.generate(questions.length, (index) {
                      final bool isSelected = currentIndex == index;

                      return GestureDetector(
                        onTap: isSubmittingAnswer
                            ? null
                            : () => _goToQuestion(index),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
                              width: 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
