import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTheme {
  // Primary brand colors - Refreshed color palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Violet
  static const Color accentColor = Color(0xFFEC4899); // Pink

  // Neutral colors
  static const Color neutralDark = Color(0xFF1F2937);
  static const Color neutralMedium = Color(0xFF6B7280);
  static const Color neutralLight = Color(0xFFF9FAFB);

  // Semantic colors
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Chatbot colors - More vibrant
  static const Color openaiColor = Color(0xFF10A37F);
  static const Color geminiColor = Color(0xFF4285F4);
  static const Color huggingfaceColor = Color(0xFFFFD21E);
  static const Color mistralColor = Color(0xFF7C3AED);
  static const Color deepinfraColor = Color(0xFFFF6B6B);
  static const Color openrouterColor = Color(0xFF00A3E1);

  // Font families
  static const String primaryFontFamily = 'Poppins';
  static const String secondaryFontFamily = 'Inter';

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: neutralLight,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: neutralDark,
      onSurface: neutralDark,
    ),
    scaffoldBackgroundColor: neutralLight,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: neutralDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: neutralDark,
      ),
      iconTheme: IconThemeData(color: neutralDark),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neutralMedium.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neutralMedium.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: TextStyle(
        color: neutralMedium.withOpacity(0.7),
        fontFamily: primaryFontFamily,
      ),
      labelStyle: TextStyle(
        color: neutralMedium,
        fontFamily: primaryFontFamily,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: neutralDark,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: neutralDark,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: neutralDark,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: neutralDark,
      ),
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: neutralDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        color: neutralDark,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        color: neutralDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    iconTheme: IconThemeData(
      color: neutralDark,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: neutralMedium.withOpacity(0.2),
      thickness: 1,
      space: 32,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: neutralMedium,
      selectedLabelStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: neutralLight,
      onSurface: neutralLight,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: neutralLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: neutralLight,
      ),
      iconTheme: IconThemeData(color: neutralLight),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neutralMedium.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neutralMedium.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: TextStyle(
        color: neutralMedium.withOpacity(0.7),
        fontFamily: primaryFontFamily,
      ),
      labelStyle: TextStyle(
        color: neutralMedium,
        fontFamily: primaryFontFamily,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: neutralLight,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: neutralLight,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: neutralLight,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: neutralLight,
      ),
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: neutralLight,
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        color: neutralLight,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        color: neutralLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    iconTheme: IconThemeData(
      color: neutralLight,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: neutralMedium.withOpacity(0.2),
      thickness: 1,
      space: 32,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: neutralMedium,
      selectedLabelStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // Platform adaptive widgets
  static Widget adaptiveProgressIndicator({Color? color}) {
    if ((kIsWeb && !isApplePlatform()) || (!kIsWeb && !isApplePlatform())) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? primaryColor),
        strokeWidth: 3,
      );
    } else {
      return CupertinoActivityIndicator(
        color: color ?? primaryColor,
        radius: 12,
      );
    }
  }

  static Widget adaptiveSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if ((kIsWeb && !isApplePlatform()) || (!kIsWeb && !isApplePlatform())) {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? primaryColor,
      );
    } else {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? primaryColor,
      );
    }
  }

  static Widget adaptiveTextField({
    required TextEditingController controller,
    String? placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefix,
    Widget? suffix,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    if ((kIsWeb && !isApplePlatform()) || (!kIsWeb && !isApplePlatform())) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: prefix,
          suffixIcon: suffix,
          enabled: enabled,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onChanged: onChanged,
      );
    } else {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: prefix != null
            ? Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: prefix,
        )
            : null,
        suffix: suffix != null
            ? Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: suffix,
        )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onChanged: onChanged,
        enabled: enabled,
      );
    }
  }

  static Widget adaptiveButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
    IconData? icon,
  }) {
    if ((kIsWeb && !isApplePlatform()) || (!kIsWeb && !isApplePlatform())) {
      return ElevatedButton(
        onPressed: isLoading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? primaryColor,
          foregroundColor: textColor ?? Colors.white,
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      );
    } else {
      return CupertinoButton(
        onPressed: isLoading ? () {} : onPressed,
        color: backgroundColor ?? primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: isLoading
            ? CupertinoActivityIndicator(
          color: textColor ?? Colors.white,
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor ?? Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  static bool isApplePlatform() {
    if (kIsWeb) {
      // For web, we can't detect the platform reliably
      return false;
    }
    return Platform.isIOS || Platform.isMacOS;
  }
}