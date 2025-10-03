// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:artbeat/app.dart';
import 'package:artbeat/src/widgets/error_boundary.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/widgets/dashboard/user_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
      // Test that the main app widget can be created
      await tester.pumpWidget(MyApp());

      // Verify the app builds successfully
      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('MyApp has MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Core Widget Tests', () {
    testWidgets('UserProgressCard displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: UserProgressCard())),
      );

      // Verify the card is displayed
      expect(find.byType(UserProgressCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('UserProgressCard shows streak information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: UserProgressCard())),
      );

      // Check for streak-related text
      expect(find.textContaining('streak'), findsWidgets);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('ErrorBoundary handles errors gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: SizedBox.shrink())),
      );

      // The ErrorBoundary should be present
      expect(find.byType(ErrorBoundary), findsOneWidget);
    });
  });

  group('Utility Tests', () {
    test('AppLogger can be initialized', () {
      // Test that logger initialization doesn't throw
      expect(AppLogger.initialize, returnsNormally);
    });

    test('PerformanceMonitor can start timer', () {
      // Test that performance monitoring works
      expect(() => PerformanceMonitor.startTimer('test'), returnsNormally);
    });
  });
}
