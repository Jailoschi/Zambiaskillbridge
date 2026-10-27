import 'package:flutter/material.dart';

/// Central palette for SkillBridge.
///
/// The brand is built on a deep navy blue with a warm amber accent that is
/// used for badges, highlights and calls to action.
class AppColors {
  const AppColors._();

  static const Color navy = Color(0xFF0B2447);
  static const Color navyDark = Color(0xFF061630);
  static const Color navyLight = Color(0xFF1B3A6B);
  static const Color navySoft = Color(0xFF2E4E7E);

  static const Color accent = Color(0xFFF2A93B);
  static const Color accentDark = Color(0xFFD98A18);

  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF10203A);
  static const Color textSecondary = Color(0xFF5C6B82);
  static const Color textOnNavy = Color(0xFFE7EDF7);

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFC0392B);
  static const Color border = Color(0xFFDCE3EE);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyDark],
  );
}
