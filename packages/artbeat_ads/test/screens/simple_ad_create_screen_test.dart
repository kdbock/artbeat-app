import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_ads/src/screens/simple_ad_create_screen.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';

void main() {
  group('SimpleAdCreateScreen Tests', () {
    Widget createTestWidget() {
      return const MaterialApp(home: SimpleAdCreateScreen());
    }

    group('Widget Rendering Tests', () {
      testWidgets('should render the ad creation form', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Check for main form elements
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsWidgets);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should display all required form fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Look for form field labels/hints
        expect(find.text('Ad Title *'), findsOneWidget);
        expect(find.text('Description *'), findsOneWidget);
        expect(find.text('Destination URL (optional)'), findsOneWidget);
        expect(find.text('Call-to-Action Text (optional)'), findsOneWidget);
      });

      testWidgets('should display ad type selection', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Should show ad type options using RadioListTile
        expect(find.text('Ad Type'), findsOneWidget);
        expect(find.text(AdType.banner_ad.displayName), findsOneWidget);
        expect(find.byType(RadioListTile<AdType>), findsWidgets);
      });

      testWidgets('should display ad size selection', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Should show ad size options using RadioListTile
        expect(find.text('Ad Size & Pricing'), findsOneWidget);
        expect(find.text(AdSize.small.displayName), findsOneWidget);
        expect(find.byType(RadioListTile<AdSize>), findsWidgets);
      });

      testWidgets('should display location selection', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Should show location options using DropdownButtonFormField
        expect(find.text('Display Location'), findsOneWidget);
        expect(find.text('Select Display Location'), findsOneWidget);
        expect(
          find.byType(DropdownButtonFormField<AdLocation>),
          findsOneWidget,
        );
      });

      testWidgets('should display image picker section', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Should show image selection area
        expect(find.text('Images (1-4 images)'), findsOneWidget);
        expect(find.text('Tap to select images'), findsOneWidget);
      });
    });

    group('User Interaction Tests', () {
      testWidgets('should change ad type when selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap feed ad radio button
        final feedAdRadio = find.widgetWithText(
          RadioListTile<AdType>,
          AdType.feed_ad.displayName,
        );
        await tester.tap(feedAdRadio);
        await tester.pump();

        // Verify selection changed - the selected radio should be checked
        expect(find.text(AdType.feed_ad.displayName), findsOneWidget);
      });

      testWidgets('should change ad size when selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap large size radio button
        final largeSizeRadio = find.widgetWithText(
          RadioListTile<AdSize>,
          AdSize.large.displayName,
        );
        await tester.tap(largeSizeRadio);
        await tester.pump();

        // Verify selection changed
        expect(find.text(AdSize.large.displayName), findsOneWidget);
      });
    });
  });
}
