import 'package:flutter/material.dart';

class AppColors {
  // Modern Minimalist Palette
  static const Color primary = Color(0xFF2563EB); // Royal Indigo Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySurface = Color(0xFFEFF6FF); // Ultra Soft Blue Tint

  // Accent / Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF06B6D4); // Cyan

  // Neutral Colors (Light) - High contrast & spacious
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate-50 background
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900 (High contrast)
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate-500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200 Crisp Outline

  // Neutral Colors (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Gradients - Subtly refined
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
