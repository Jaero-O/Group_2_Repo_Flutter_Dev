import 'package:flutter/material.dart';

/// Central class for application-wide theme constants.
class AppTheme {
  // --- Color Constants ---
  /// Start color for the main green gradient (Dark Green).
  static const Color topColorStart = Color(0xFF007700);
  
  /// End color for the main green gradient (Light Green/Yellow).
  static const Color topColorEnd = Color(0xFFC9FF8E);

  // --- Gradient Constants ---
  /// Linear gradient used for the primary top header background.
  static const LinearGradient kGreenGradient = LinearGradient(
    colors: [topColorStart, topColorEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Private constructor to prevent instantiation
  AppTheme._();
}