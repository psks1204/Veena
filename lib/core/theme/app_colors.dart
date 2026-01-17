import 'package:flutter/material.dart';

/// Veena Design System - Color Palette
/// 
/// Premium color system with carefully balanced dark and light themes.
/// All colors are designed to work together harmoniously.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────
  
  /// Deep charcoal background (not pure black)
  static const Color darkBg = Color(0xFF121212);
  
  /// Elevated surface color for cards
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// Secondary elevated surface
  static const Color darkSurfaceVariant = Color(0xFF282828);
  
  /// Primary text - off-white, not stark white
  static const Color darkTextPrimary = Color(0xFFEDEDED);
  
  /// Secondary text for metadata
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  
  /// Tertiary text for disabled states
  static const Color darkTextTertiary = Color(0xFF727272);

  // ─────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────
  
  /// Soft off-white background (not pure white)
  static const Color lightBg = Color(0xFFF7F7F7);
  
  /// Pure white surface for cards
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// Muted gray secondary surface
  static const Color lightSurfaceVariant = Color(0xFFEEEEEE);
  
  /// Primary text - deep charcoal
  static const Color lightTextPrimary = Color(0xFF121212);
  
  /// Secondary text for metadata
  static const Color lightTextSecondary = Color(0xFF666666);
  
  /// Tertiary text for disabled states
  static const Color lightTextTertiary = Color(0xFF999999);

  // ─────────────────────────────────────────────────────────────────
  // ACCENT COLORS
  // ─────────────────────────────────────────────────────────────────
  
  /// Primary brand accent - rich green
  static const Color accent = Color(0xFF1DB954);
  
  /// Accent variant for hover/pressed states
  static const Color accentVariant = Color(0xFF1ED760);
  
  /// Error state
  static const Color error = Color(0xFFE53935);
  
  /// Success state
  static const Color success = Color(0xFF1DB954);

  // ─────────────────────────────────────────────────────────────────
  // OVERLAY COLORS
  // ─────────────────────────────────────────────────────────────────
  
  /// Semi-transparent overlay for modals
  static const Color overlayDark = Color(0x99000000);
  
  /// Gradient overlay for artwork
  static const Color gradientStart = Color(0x00000000);
  static const Color gradientEnd = Color(0xCC000000);
}
