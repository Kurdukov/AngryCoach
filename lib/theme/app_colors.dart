import 'package:flutter/material.dart';

/// Semantic color tokens for the redesign.
///
/// The previous palette painted whole screens and cards in one of five or
/// six saturated colors (blue, lime, yellow, pink, pastel blue, orange),
/// which is what made the app feel loud. This palette has exactly one
/// brand accent plus a neutral surface system — status colors exist, but
/// are meant for small accents (an icon, a thin bar, a dot), never a full
/// screen or card fill.
class AppColors {
  const AppColors._();

  // The one color allowed to carry visual weight across the app.
  static const accent = Color(0xFF3D5AFE);
  static const accentSoft = Color(0xFFDCE3FF);

  // Neutral surfaces — light.
  static const background = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEEF0F5);
  static const ink = Color(0xFF14161F);
  static const muted = Color(0xFF6C707C);
  static const stroke = Color(0xFFE6E8EE);

  // Neutral surfaces — dark.
  static const darkBackground = Color(0xFF0B0C10);
  static const darkSurface = Color(0xFF15171E);
  static const darkSurfaceAlt = Color(0xFF1C1F28);
  static const darkStroke = Color(0xFF2A2D38);

  // Status accents — small touches only (icon, dot, thin bar).
  static const success = Color(0xFF2FB574);
  static const danger = Color(0xFFE5484D);
  static const warning = Color(0xFFC98A1E);
}
