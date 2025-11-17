import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A reusable widget for the application's top header background.
/// It displays the standard kGreenGradient and is typically positioned 
/// at the top of a Stack.
class GreenHeaderBackground extends StatelessWidget {
  /// The required height of the header area.
  final double height;
  
  const GreenHeaderBackground({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kGreenGradient),
      ),
    );
  }
}