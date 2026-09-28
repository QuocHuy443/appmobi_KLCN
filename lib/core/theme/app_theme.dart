import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.medical500),
      textTheme: GoogleFonts.interTextTheme(),
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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.medical500,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate800,
        elevation: 0,
        centerTitle: true,
        // Đã sửa IconData thành IconThemeData ở dòng bên dưới
        iconTheme: IconThemeData(color: AppColors.slate100),
        titleTextStyle: TextStyle(
          color: AppColors.slate100,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
