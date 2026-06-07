import 'package:driving_quiz_app/userRoles.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomResponsiveNavbar.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  UserRoles _selectedRole = UserRoles.guest;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUpSubmit() {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "role": _selectedRole.name
      };
      print("تم إرسال البيانات للمخدم: $payload");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            appBar: const CustomResponsiveNavbar(),
            backgroundColor: AppColors.background,
            body: LayoutBuilder(builder: (context, constraints) {
              if (BreakPoint.isDesktop(constraints.maxWidth) ||
                  (BreakPoint.isTablet(constraints.maxWidth))) {
                return Center(
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 600, maxHeight: 600),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]),
                    child: Row(children: [
                      // Expanded(
                      //   child: Container(
                      //     decoration: const BoxDecoration(
                      //       color: AppColors.primaryGreen,
                      //       borderRadius: BorderRadius.only(
                      //         topLeft: Radius.circular(16),
                      //         bottomLeft: Radius.circular(16),
                      //       ),
                      //     ),
                      //     padding: const EdgeInsets.all(32),
                      //     child: const Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           "مرحباً بك في منصة القيادة ",
                      //           style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 28,
                      //               fontWeight: FontWeight.bold),
                      //         ),
                      //         SizedBox(height: 16),
                      //         Text(
                      //           "أنشئ حسابك الآن لتتمكن من حفظ تقدمك، ومشاركة الأسئلة والأقسام مع الممارسين الآخرين.",
                      //           style: TextStyle(
                      //               color: Colors.white70,
                      //               fontSize: 16,
                      //               height: 1.5),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: _buildSignUpForm(),
                        ),
                      ),
                    ]),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 60.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "إنشاء حساب جديد ",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepForest),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "انضم إلينا وابدأ مسيرتك التعليمية اليوم",
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildSignUpForm(),
                  ],
                ),
              );
            })));
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          // حقل الاسم
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل *',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppColors.primaryGreen),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'يرجى إدخال اسمك الكامل'
                : null,
          ),
          const SizedBox(height: 20),

          // حقل البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني *',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.primaryGreen),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'يرجى إدخال البريد الإلكتروني';
              if (!value.contains('@')) return 'يرجى إدخال بريد إلكتروني صحيح';
              return null;
            },
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور *',
              prefixIcon:
                  Icon(Icons.lock_outline, color: AppColors.primaryGreen),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.length < 6
                ? 'كلمة المرور يجب أن تكون 6 أحرف أو أكثر'
                : null,
          ),
          const SizedBox(height: 24),

          // نظام اختيار الصلاحيات (Roles Dropdown) بناءً على الـ Enum
          const Text(
            "نوع الحساب / الصلاحية",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
              color: AppColors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRoles>(
                value: _selectedRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: UserRoles.guest,
                    child: Text("ممارس / زائر عادي (Guest)"),
                  ),
                  DropdownMenuItem(
                    value: UserRoles.admin,
                    child: Text("مشرف محتوى / مدرب (Admin)"),
                  ),
                ],
                onChanged: (UserRoles? newRole) {
                  if (newRole != null) {
                    setState(() {
                      _selectedRole = newRole;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _signUpSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'إنشاء الحساب',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
