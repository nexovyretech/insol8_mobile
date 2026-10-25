import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final soraTextTheme = GoogleFonts.soraTextTheme().copyWith(
      headlineSmall: GoogleFonts.sora(
        color: AppColors.ink,
        fontSize: 23,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.sora(
        color: AppColors.ink,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: GoogleFonts.workSans(
        color: AppColors.body,
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.error,
      ),
      textTheme: soraTextTheme,
      fontFamily: GoogleFonts.sora().fontFamily,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        hintStyle: GoogleFonts.sora(color: AppColors.fieldHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
