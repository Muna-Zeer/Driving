import 'package:driving_quiz_app/widgets/breakpoint.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (BreakPoint.isDesktop(constraints.maxWidth)) {
        return desktop;
      }
      if (BreakPoint.isTablet(constraints.maxWidth)) {
        return tablet ?? desktop;
      }
      return mobile;
    });
  }
}
