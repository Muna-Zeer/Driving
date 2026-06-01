// app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // 1. Your Custom Green Palette (Extracted from your image)
  static const Color primaryGreen = Color(0xFF386641);       // Top dark green
  static const Color secondarySage = Color(0xFF8BBE8A);      // Middle light sage
  static const Color deepForest = Color(0xFF132A13);         // Dark forest tone
  static const Color accentNeon = Color(0xFF1DFF54);         // Bright neon accent

  // 2. Essential UI Neutrals (Crucial for cards, text, and clean space)
  static const Color background = Color(0xFFF8F9FA);         // Light grey page canvas
  static const Color surface = Color(0xFFFFFFFF);            // Clean white for cards/navbars
  static const Color border = Color(0xFFE9ECEF);             // Subtle lines and dividers

  // 3. Text Hierarchy Colors
  static const Color textPrimary = Color(0xFF212529);        // Deep charcoal for main reading text
  static const Color textSecondary = Color(0xFF6C757D);      // Slate grey for subtitles/secondary text
  static const Color textLight = Color(0xFFFFFFFF);          // White text for inside green buttons

  // 4. Functional Semantic Colors (Standard for apps with quizzes/tests)
  static const Color success = Color(0xFF2EA44F);            // Pass state / Correct choice
  static const Color error = Color(0xFFD90429);              // Fail state / Incorrect choice
  static const Color warning = Color(0xFFFFB703);            // Alert state / Skipped questions
}