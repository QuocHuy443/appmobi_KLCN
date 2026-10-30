import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: AppColors.slate900,
      displayColor: AppColors.slate900,
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.medical600,
        brightness: Brightness.light,
        primary: AppColors.medical600,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.slate900,
      ),
      textTheme: baseTextTheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.slate800),
        titleTextStyle: TextStyle(
          color: AppColors.slate800,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.slate700,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.medical700,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: AppColors.slate400,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: AppColors.medical600,
        suffixIconColor: AppColors.slate600,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.medical600, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.medical600,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.medical600.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
