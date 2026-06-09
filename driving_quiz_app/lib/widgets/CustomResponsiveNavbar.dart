import 'package:driving_quiz_app/views/SignUp.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CustomResponsiveNavbar extends StatefulWidget
    implements PreferredSizeWidget {
  const CustomResponsiveNavbar({Key? key}) : super(key: key);

  @override
  State<CustomResponsiveNavbar> createState() => _CustomResponsiveNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}

class _CustomResponsiveNavbarState extends State<CustomResponsiveNavbar> {
  final _storage = const FlutterSecureStorage();
  bool _isLoggin = false;
  String _userRole = 'guest';

  Future<void> _checkLoginUser() async {
    String? token = await _storage.read(key: 'auth_token');
    String? role = await _storage.read(key: 'user_role');
    if (token != null) {
      setState(() {
        _isLoggin = true;
        _userRole = role ?? 'guest';
      });
    }
  }

  Future<void> logOut() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_role');
    setState(() {
      _isLoggin = false;
      _userRole = 'guest';
    });
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool showFullNavbar =
        BreakPoint.isDesktop(screenWidth) || BreakPoint.isTablet(screenWidth);

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 1,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[700],
            radius: 18,
            child: const Icon(Icons.drive_eta, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'موقعي',
            style: TextStyle(
              color: AppColors.deepForest,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: showFullNavbar
          ? [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavbarItem('الرئيسية', isActive: true),
                    _buildNavbarItem(
                      'تسجيل الدخول',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                    ),
                    _buildNavbarItem('أسئلة التورق'),
                    _buildNavbarItem('دراسة التورق'),
                    _buildNavbarItem('الامتحان التجريبي'),
                    _buildNavbarItem('اتصل بنا'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ],
    );
  }

  Widget _buildNavbarItem(String title,
      {bool isActive = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor:
              isActive ? AppColors.primaryGreen : AppColors.textPrimary,
        ),
        onPressed: onTap ?? () {},
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
