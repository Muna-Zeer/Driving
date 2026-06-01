class BreakPoint {
  static const double mobileMax = 600;
  static const double tableMax = 1100;

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) => width >= mobileMax && width < tableMax;
  static bool isDesktop(double width) => width >= tableMax;
}
