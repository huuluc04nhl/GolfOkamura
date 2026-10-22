import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Theme dành cho Web Admin Dashboard
class AdminTheme {
  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.adminBg,
      visualDensity: VisualDensity.compact,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGold,
        onPrimary: Colors.black,
        secondary: AppColors.adminSidebar,
        onSecondary: Colors.white,
        surface: AppColors.adminCard,
        onSurface: AppColors.adminText,
        error: AppColors.statusBooked,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.adminText,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.adminText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.adminText,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.adminMuted,
          fontSize: 13,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.adminCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.adminBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.adminText),
        titleTextStyle: TextStyle(
          color: AppColors.adminText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
