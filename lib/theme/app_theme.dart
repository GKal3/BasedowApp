import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Stile di testo Manrope. Uso: `AppText.t(14, w: FontWeight.w800)`.
class AppText {
  AppText._();

  static TextStyle t(
    double size, {
    FontWeight w = FontWeight.w600,
    Color c = AppColors.navy,
    double? h,
    double? ls,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.amber,
        surface: AppColors.sky50,
        error: AppColors.danger,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.sky50,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.navy,
        selectionHandleColor: AppColors.sky300,
      ),
    );
  }
}
