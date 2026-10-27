import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens for SkillBridge.
///
/// The palette comes from [AppColors] (deep navy, warm amber) so the whole app
/// keeps the brand established in Part 1, while the token names below are
/// shared by every screen.
class SB {
  SB._();

  static const navy = AppColors.navy;
  static const blueGrey = AppColors.textSecondary;
  static const bg = AppColors.background;
  static const card = AppColors.surface;
  static const text = AppColors.textPrimary;
  static const text2 = AppColors.textSecondary;
  static const border = AppColors.border;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const error = AppColors.danger;

  /// Primary interactive colour.
  static const accent = AppColors.navy;

  static const soft = Color(0xFFEDF2FA);

  // Warm accents kept for prices, badges and highlights.
  static const terracotta = AppColors.warning;
  static const ochre = AppColors.accent;
  static const sage = AppColors.success;
  static const navyLight = AppColors.navyLight;

  static const _f = 'Jakarta';

  static const h0 = TextStyle(
    fontFamily: _f,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: text,
    letterSpacing: -0.8,
  );
  static const h0Navy = TextStyle(
    fontFamily: _f,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: navy,
    letterSpacing: -0.8,
  );
  static const h1 = TextStyle(
    fontFamily: _f,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: text,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const h1Navy = TextStyle(
    fontFamily: _f,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: navy,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const h2 = TextStyle(
    fontFamily: _f,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: text,
    height: 1.25,
    letterSpacing: -0.3,
  );
  static const h3 = TextStyle(
    fontFamily: _f,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: text,
  );
  static const h4 = TextStyle(
    fontFamily: _f,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: text,
  );

  static const double radius = 16;
  static const double radiusSm = 12;
  static const double pad = 16;
  static const double gap = 12;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Jakarta',
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: SB.navy,
    brightness: Brightness.light,
  ).copyWith(
    primary: SB.navy,
    onPrimary: Colors.white,
    secondary: SB.ochre,
    onSecondary: SB.navy,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    error: SB.error,
    outline: SB.border,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: SB.bg,
    textTheme: base.textTheme.apply(
      bodyColor: SB.text,
      displayColor: SB.text,
      fontFamily: 'Jakarta',
    ).copyWith(
      displaySmall: const TextStyle(fontFamily: 'Jakarta', fontSize: 32, fontWeight: FontWeight.w700, color: SB.text, letterSpacing: -0.5),
      headlineMedium: const TextStyle(fontFamily: 'Jakarta', fontSize: 26, fontWeight: FontWeight.w700, color: SB.text, height: 1.2, letterSpacing: -0.3),
      headlineSmall: const TextStyle(fontFamily: 'Jakarta', fontSize: 22, fontWeight: FontWeight.w700, color: SB.text),
      titleLarge: const TextStyle(fontFamily: 'Jakarta', fontSize: 18, fontWeight: FontWeight.w700, color: SB.text),
      titleMedium: const TextStyle(fontFamily: 'Jakarta', fontSize: 16, fontWeight: FontWeight.w600, color: SB.text),
      bodyLarge: const TextStyle(fontFamily: 'Jakarta', fontSize: 16, height: 1.45, color: SB.text),
      bodyMedium: const TextStyle(fontFamily: 'Jakarta', fontSize: 14, height: 1.45, color: SB.text2),
      labelLarge: const TextStyle(fontFamily: 'Jakarta', fontSize: 14, fontWeight: FontWeight.w600, color: SB.text),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SB.bg,
      foregroundColor: SB.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: SB.h4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(SB.navy, 1.6),
      errorBorder: border(SB.error),
      focusedErrorBorder: border(SB.error, 1.6),
      labelStyle: const TextStyle(color: SB.text2),
      hintStyle: const TextStyle(color: SB.text2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SB.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Jakarta',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SB.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Jakarta',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SB.navy,
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: AppColors.border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Jakarta',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SB.navy,
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(
          fontFamily: 'Jakarta',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: SB.soft,
      selectedColor: SB.navy,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SB.text,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 13,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: SB.border, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SB.navy,
      contentTextStyle: const TextStyle(
        fontFamily: 'Jakarta',
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: SB.navy),
  );
}

/// Kept for code written against the Part 1 theme API.
class AppTheme {
  const AppTheme._();
  static ThemeData get light => buildTheme();
}
