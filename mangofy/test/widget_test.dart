import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:mangofy/splash_screen.dart';

void main() {
  testWidgets('Splash screen transitions to target page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          targetPage: Scaffold(body: Center(child: Text('Target Page'))),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Target Page'), findsOneWidget);
  });
}
