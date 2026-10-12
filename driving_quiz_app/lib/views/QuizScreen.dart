import 'dart:convert';
import 'package:driving_quiz_app/models/question_model.dart';
import 'package:driving_quiz_app/services/APIService.dart';
import 'package:driving_quiz_app/services/AdminService.dart';
import 'package:driving_quiz_app/services/QuestionService.dart';
import 'package:driving_quiz_app/views/ManageQuestionDialog.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/drivingAlerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Import your model file here
class QuizScreen extends StatefulWidget {
  final String levelId;

  const QuizScreen({Key? key, required this.levelId}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final baseUrl = APIService.getBaseUrl();
  QuestionService _apiService = QuestionService();
  List<QuestionModel> questions = [];
  bool _isLoading = true;
  int currentIndex = 0;
  String? selectedOptionId;
  bool isAnswerChecked = false;
  String currentLocale = "ar";
  final AdminService _authService = AdminService();
  bool _isAdmin = false;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    _initAdminRole();
  }

  Future<void> _initAdminRole() async {
    await _authService.loadUserRole();
    setState(() {
      _isAdmin = _authService.isAdmin;
    });
  }

  Future<void> fetchQuestions() async {
    try {
      final accessToken = await _storage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/levels/${widget.levelId}/questions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List? ?? [];

        List<QuestionModel> parsedQuestions =
            list.map((q) => QuestionModel.fromJson(q)).toList();
        parsedQuestions.sort((a, b) => a.order.compareTo(b.order));

        if (parsedQuestions.isEmpty) {
          currentIndex = 0;
        } else if (currentIndex >= parsedQuestions.length) {
          currentIndex = parsedQuestions.length - 1;
        }

        setState(() {
          questions = parsedQuestions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Network or parsing error: $e');
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomResponsiveNavbar(),
        body: const Center(
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ManageQuestionDialog(levelId: widget.levelId),
                      ),
                    );

                    if (result == true) {
                      fetchQuestions();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سؤال جديد'),
                ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondarySage.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'السؤال ${currentQuestion.order} من ${questions.length}',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (_isAdmin)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.primaryGreen,
                                        size: 20),
                                    tooltip: 'تعديل السؤال',
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error, size: 20),
                                    tooltip: 'حذف السؤال',
                                    onPressed: () => handleDeleteQuestion(
                                        context, questions[currentIndex].id),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: AppColors.textLight,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ManageQuestionDialog(
                                                  levelId: widget.levelId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('إضافة سؤال',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Image Container (if available)
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
                                  ? ['أ', 'ب', 'ج', 'د'][idx]
                                  : '${idx + 1}';
                          bool isSelected =
                              selectedOptionId == option.identifier;

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

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                if (!isAnswerChecked) {
                                  setState(() =>
                                      selectedOptionId = option.identifier);
                                }
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
                                      child: Text(
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
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        if (_isAdmin) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 16,
                                                color: AppColors.textSecondary),
                                            tooltip: 'تعديل الخيار',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            onPressed: () {
                                              // Implement option update action here
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                        ],
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
                const SizedBox(height: 24),
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = selectedOptionId == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            currentIndex = index;
                            selectedOptionId = null;
                            isAnswerChecked = false;
                          });
                        },
                        child: Container(
                          width: 46,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                            ],
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onPressed: currentIndex > 0
                            ? () => setState(() {
                                  currentIndex--;
                                  selectedOptionId = null;
                                  isAnswerChecked = false;
                                })
                            : null,
                        child: const Text('السابق',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.textLight,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: selectedOptionId != null && !isAnswerChecked
                            ? () => setState(() => isAnswerChecked = true)
                            : null,
                        child: const Text('تحقق من الإجابة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onPressed: currentIndex < questions.length - 1
                            ? () => setState(() {
                                  currentIndex++;
                                  selectedOptionId = null;
                                  isAnswerChecked = false;
                                })
                            : null,
                        child: const Text('التالي',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
