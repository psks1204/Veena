import 'package:flutter/material.dart';

/// Veena Design System - Color Palette
/// 
/// Aura Design System colors.
/// Premium, high-contrast, and vibrant.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────
  // BRAND & ACCENT
  // ─────────────────────────────────────────────────────────────────
  
  /// Primary Brand Color - "Primary" (#d41173)
  static const Color primary = Color(0xFFD41173);
  
  /// Success / Functional Green
  static const Color success = Color(0xFF1DB954);
  
  /// Error / Functional Red
  static const Color error = Color(0xFFE53935);

  // ─────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────
  
  /// Deep dark background (#131315)
  static const Color darkBg = Color(0xFF131315);
  
  /// Surface Dark (#1D1E1F or #1E1E20 depending on usage, unifying to #1D1E1F)
  static const Color darkSurface = Color(0xFF1D1E1F);
  
  /// Secondary Surface / Card Highlight (#2A2A2D)
  static const Color darkSurfaceVariant = Color(0xFF2A2A2D);
  
  /// Primary Text - White
  static const Color darkTextPrimary = Colors.white;
  
  /// Muted Text (#A0A3A6)
  static const Color darkTextSecondary = Color(0xFFA0A3A6);

  // ─────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────
  
  /// Light Background (#F7F7F7)
  static const Color lightBg = Color(0xFFF7F7F7);
  
  /// Surface Light (#FFFFFF or #EBEBEB)
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// Variant Surface (#EBEBEB or #F0F0F0)
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);
  
  /// Primary Text (#2D2D2D)
  static const Color lightTextPrimary = Color(0xFF2D2D2D);
  
  /// Muted Text (#7B7B7B)
  static const Color lightTextSecondary = Color(0xFF7B7B7B);
}
