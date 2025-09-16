// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoadingScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(home: LoadingScreen(enableNavigation: false)),
    );

    // Verify that we have a LoadingScreen
    expect(find.byType(LoadingScreen), findsOneWidget);

    // Verify that the loading text is displayed
    expect(find.text('Loading your artistic journey...'), findsOneWidget);

    // Verify that the logo image is present
    expect(find.byType(Image), findsOneWidget);

    // Pump a few frames to let animations start (but don't settle since they're continuous)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify LoadingScreen is still present (since we disabled navigation in tests)
    expect(find.byType(LoadingScreen), findsOneWidget);
  });
}
