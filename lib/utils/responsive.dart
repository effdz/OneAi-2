import 'package:flutter/material.dart';

/// A utility class that provides responsive design helpers
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
          MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Returns a value based on the screen size
  /// [mobile] value for mobile screens
  /// [tablet] value for tablet screens
  /// [desktop] value for desktop screens
  static T responsive<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        required T desktop,
      }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Returns a responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive<EdgeInsets>(
      context,
      mobile: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
    );
  }

  /// Returns a responsive font size based on screen size
  static double responsiveFontSize(
      BuildContext context, {
        required double mobile,
        double? tablet,
        required double desktop,
      }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
