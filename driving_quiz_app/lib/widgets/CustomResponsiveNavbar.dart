
import 'package:driving_quiz_app/widgets/AppColors.dart';
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
  bool _isLoggedIn = false;
  String _userRole = '';
  String _userName = '';

  Future<void> _loadAuthStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    String? role = await _storage.read(key: 'user_role');
    String? name = await _storage.read(key: 'user_name');

    if (token != null) {
      setState(() {
        _isLoggedIn = true;
        _userRole = role ?? 'guest';
        _userName = name ?? '';
      });
    }
  }

  Future<void> logOut() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_name');
    setState(() {
      _isLoggedIn = false;
      _userRole = '';
      _userName = '';
    });
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 900;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.directions_car,
              color: AppColors.primaryGreen, size: 28),
          const SizedBox(width: 8),
          const Text(
            'موقعي',
            style: TextStyle(
              color: AppColors.deepForest,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: 'Tajawal',
            ),
          ),
          if (_isLoggedIn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _userRole == 'admin' ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _userRole == 'admin' ? 'مسؤول' : 'زائر مسجل',
                style: TextStyle(
                  color: _userRole == 'admin'
                      ? Colors.red[700]
                      : AppColors.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]
        ],
      ),
      actions: isDesktop
          ? [Row(children: _buildNavbarItems(isMobile: false))]
          : [
              IconButton(
                icon: const Icon(Icons.menu,
                    color: AppColors.deepForest, size: 28),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              const SizedBox(width: 10),
            ],
    );
  }

  List<Widget> _buildNavbarItems({required bool isMobile}) {
    List<Widget> items = [];

    items.add(_buildItem('الرئيسية',
        icon: Icons.home_outlined, isMobile: isMobile, onTap: () {
      Navigator.pushNamed(context, '/');
    }));

    if (!_isLoggedIn) {
      items.add(_buildItem('تسجيل الدخول',
          icon: Icons.login_outlined, isMobile: isMobile, onTap: () {
        Navigator.pushNamed(context, '/login');
      }));
      items.add(_buildItem('إنشاء حساب',
          icon: Icons.person_add_alt_outlined, isMobile: isMobile, onTap: () {
        Navigator.pushNamed(context, '/signup');
      }));
    } else {
      if (_userRole == 'admin') {
        items.add(_buildItem('لوحة التحكم ⚙️',
            icon: Icons.dashboard_customize_outlined,
            isMobile: isMobile, onTap: () {
          Navigator.pushNamed(context, '/admin/dashboard');
        }));
        items.add(_buildItem('إدارة الأسئلة',
            icon: Icons.quiz_outlined, isMobile: isMobile, onTap: () {
          Navigator.pushNamed(context, '/admin/questions');
        }));
        items.add(_buildItem('إضافة تصنيف',
            icon: Icons.add_box_outlined, isMobile: isMobile, onTap: () {
          Navigator.pushNamed(context, '/admin/add-category');
        }));
      } else if (_userRole == 'guest') {
        items.add(_buildItem('الامتحانات التجريبية',
            icon: Icons.drive_eta_outlined, isMobile: isMobile, onTap: () {
          Navigator.pushNamed(context, '/guest/quizzes');
        }));
        items.add(_buildItem('نتائجي',
            icon: Icons.analytics_outlined, isMobile: isMobile, onTap: () {
          Navigator.pushNamed(context, '/guest/results');
        }));
        items.add(_buildItem('ترقية الحساب ',
            icon: Icons.verified_user_outlined,
            isMobile: isMobile,
            textColor: AppColors.primaryGreen, onTap: () {
          Navigator.pushNamed(context, '/guest/upgrade');
        }));
      }

      items.add(_buildItem('تسجيل الخروج',
          icon: Icons.logout_outlined,
          isMobile: isMobile,
          textColor: Colors.redAccent,
          onTap: logOut));
    }

    return items;
  }

  Widget _buildItem(String title,
      {required IconData icon,
      required bool isMobile,
      Color? textColor,
      VoidCallback? onTap}) {
    if (isMobile) {
      return ListTile(
        leading: Icon(icon, color: textColor ?? AppColors.deepForest),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Tajawal',
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (onTap != null) onTap();
        },
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              title,
              style: TextStyle(
                color: textColor ?? AppColors.deepForest,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),
      );
    }
  }
}
