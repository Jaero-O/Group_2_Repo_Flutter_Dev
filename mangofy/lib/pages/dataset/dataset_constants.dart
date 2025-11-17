import 'package:flutter/material.dart';

/// A class to hold static constants for the DatasetPage UI.
class DatasetConstants {
  // Color constants
  static const Color topColorStart = Color(0xFF007700);
  static const Color topColorEnd = Color(0xFFC9FF8E);

  // Dimension constants
  static const double kTopHeaderHeight = 220.0;
  static const double kTopRadius = 70.0;
  static const double kContainerOverlap = 60.0;
  static const double kBottomRadius = 24.0;
  static const double kTitleTopPadding = 45.0;

  /// Gradient used for the top header background
  static const LinearGradient kGreenGradient = LinearGradient(
    colors: [topColorStart, topColorEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Private constructor to prevent instantiation
  DatasetConstants._();
}