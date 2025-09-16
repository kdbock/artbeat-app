import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_community/artbeat_community.dart';

// Simple widget test for Artist Onboarding Screen (without Firebase dependencies)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artist Onboarding Widget Tests', () {
    testWidgets('Artist Onboarding Screen renders basic UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ArtistOnboardingScreen()),
      );

      // Verify the screen title
      expect(find.text('Become an Artist'), findsOneWidget);

      // Verify step 1 content
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Tell us about yourself'), findsOneWidget);

      // Verify form fields exist
      expect(find.text('Display Name *'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);
    });

    testWidgets('Can enter text in form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ArtistOnboardingScreen()),
      );

      // Find the display name text field
      final displayNameField = find.byType(TextField).first;

      // Enter text
      await tester.enterText(displayNameField, 'Test Artist Name');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Test Artist Name'), findsOneWidget);
    });

    testWidgets('Specialty selection chips are displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ArtistOnboardingScreen()),
      );

      // Navigate to step 2
      await tester.enterText(find.byType(TextField).first, 'Test Artist');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify step 2 content
      expect(find.text('Your Specialties'), findsOneWidget);
      expect(find.text('What type of art do you create?'), findsOneWidget);

      // Verify specialty options
      expect(find.text('Painting'), findsOneWidget);
      expect(find.text('Digital Art'), findsOneWidget);
      expect(find.text('Photography'), findsOneWidget);
    });

    testWidgets('Portfolio step shows correct content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ArtistOnboardingScreen()),
      );

      // Navigate to step 3
      await tester.enterText(find.byType(TextField).first, 'Test Artist');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Painting'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify step 3 content
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Showcase your artwork'), findsOneWidget);
      expect(find.text('Add up to 10 images of your artwork:'), findsOneWidget);
    });

    testWidgets('Completion message is shown on final step', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ArtistOnboardingScreen()),
      );

      // Navigate to final step
      await tester.enterText(find.byType(TextField).first, 'Test Artist');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Painting'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify completion message
      expect(find.text('Ready to join the artist community!'), findsOneWidget);
      expect(
        find.text('Once you create your profile, you\'ll be able to:'),
        findsOneWidget,
      );
    });
  });
}
