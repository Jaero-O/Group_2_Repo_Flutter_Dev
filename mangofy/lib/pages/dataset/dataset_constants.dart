import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

/// A class to hold static constants for the DatasetPage UI.
class DatasetConstants {
  // Dimension constants
  static const double kTopHeaderHeight = 220.0;
  static const double kTopRadius = 70.0;
  static const double kContainerOverlap = 60.0;
  static const double kBottomRadius = 24.0;
  static const double kTitleTopPadding = 45.0;

  // The gradient is accessed from AppTheme
  static const LinearGradient kGreenGradient = AppTheme.kGreenGradient;
  
  // Private constructor to prevent instantiation
  DatasetConstants._();
}