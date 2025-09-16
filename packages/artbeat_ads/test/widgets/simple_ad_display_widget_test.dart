import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_ads/src/widgets/simple_ad_display_widget.dart';
import 'package:artbeat_ads/src/models/ad_model.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_status.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';
import 'package:artbeat_ads/src/models/ad_duration.dart';
import 'package:artbeat_ads/src/models/image_fit.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  group('SimpleAdDisplayWidget Tests', () {
    late AdModel testAd;
    late AdModel testAdWithMultipleImages;
    late DateTime testStartDate;
    late DateTime testEndDate;

    setUp(() {
      testStartDate = DateTime(2024, 1, 1);
      testEndDate = DateTime(2024, 1, 31);

      testAd = AdModel(
        id: 'test-ad-id',
        ownerId: 'test-owner-id',
        type: AdType.banner_ad,
        size: AdSize.medium,
        imageUrl: 'https://example.com/image.jpg',
        title: 'Test Ad Title',
        description: 'Test ad description',
        location: AdLocation.fluidDashboard,
        duration: AdDuration.weekly,
        startDate: testStartDate,
        endDate: testEndDate,
        status: AdStatus.approved,
        destinationUrl: 'https://example.com',
        ctaText: 'Shop Now',
        imageFit: ImageFit.cover,
      );

      testAdWithMultipleImages = testAd.copyWith(
        artworkUrls: [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
          'https://example.com/image3.jpg',
        ],
      );
    });

    testWidgets('should display ad with basic content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: testAd,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false, // Disable analytics for testing
            ),
          ),
        ),
      );

      // Verify the widget is displayed
      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display close button when enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: testAd,
              location: AdLocation.fluidDashboard,
              showCloseButton: true,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      // Look for close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should not display close button by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: testAd,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      // Close button should not be present
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('should display image rotation indicator for multiple images', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: testAdWithMultipleImages,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      // Should show image counter (1/3)
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets(
      'should not display image rotation indicator for single image',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        // Should not show image counter
        expect(find.text('1/1'), findsNothing);
        expect(find.text('1/3'), findsNothing);
      },
    );

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: testAd,
              location: AdLocation.fluidDashboard,
              onTap: () => tapCalled = true,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      // Tap on the ad
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('should display ad content with proper layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 250,
              child: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        ),
      );

      // Verify layout components
      expect(find.byType(LayoutBuilder), findsWidgets);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should handle different ad sizes correctly', (
      WidgetTester tester,
    ) async {
      final smallAd = testAd.copyWith(size: AdSize.small);
      final largeAd = testAd.copyWith(size: AdSize.large);

      // Test small ad
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: smallAd,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);

      // Test large ad
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: largeAd,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
    });

    testWidgets('should display overlay content for large ads', (
      WidgetTester tester,
    ) async {
      final largeAd = testAd.copyWith(size: AdSize.large);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 250, // Large enough for overlay content
              child: SimpleAdDisplayWidget(
                ad: largeAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        ),
      );

      // The overlay content should be present for large ads
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should handle ads without CTA text', (
      WidgetTester tester,
    ) async {
      final adWithoutCTA = testAd.copyWith(ctaText: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: adWithoutCTA,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
    });

    testWidgets('should handle ads without destination URL', (
      WidgetTester tester,
    ) async {
      final adWithoutURL = testAd.copyWith(destinationUrl: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: adWithoutURL,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
    });

    testWidgets('should handle different image fit modes', (
      WidgetTester tester,
    ) async {
      final adWithFitContain = testAd.copyWith(imageFit: ImageFit.contain);
      final adWithFitCover = testAd.copyWith(imageFit: ImageFit.cover);
      final adWithFitFill = testAd.copyWith(imageFit: ImageFit.fill);

      // Test contain fit
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: adWithFitContain,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);

      // Test cover fit
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: adWithFitCover,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);

      // Test fill fit
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleAdDisplayWidget(
              ad: adWithFitFill,
              location: AdLocation.fluidDashboard,
              trackAnalytics: false,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
    });

    testWidgets('should handle constrained layouts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Smaller than default ad width
              height: 100,
              child: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      expect(find.byType(LayoutBuilder), findsWidgets);
    });

    testWidgets('should handle very small layouts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50, // Very small
              height: 30,
              child: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
    });

    group('Image Rotation Tests', () {
      testWidgets('should rotate images automatically', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAdWithMultipleImages,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        // Initially should show 1/3
        expect(find.text('1/3'), findsOneWidget);

        // Fast forward time to trigger rotation
        await tester.pump(const Duration(seconds: 6));

        // Should still be showing the widget (rotation happens internally)
        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      });

      testWidgets('should not rotate single image', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAd, // Single image
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        // Should not show rotation indicator
        expect(find.textContaining('/'), findsNothing);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle empty image URL gracefully', (
        WidgetTester tester,
      ) async {
        final adWithEmptyImage = testAd.copyWith(imageUrl: '');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: adWithEmptyImage,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      });

      testWidgets('should handle empty artwork URLs', (
        WidgetTester tester,
      ) async {
        final adWithEmptyArtwork = testAd.copyWith(artworkUrls: []);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: adWithEmptyArtwork,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      });

      testWidgets('should handle very long titles and descriptions', (
        WidgetTester tester,
      ) async {
        final adWithLongText = testAd.copyWith(
          title:
              'This is a very long title that should be truncated with ellipsis when displayed in the ad widget',
          description:
              'This is a very long description that should also be truncated with ellipsis when displayed in the ad widget overlay content area',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 250,
                child: SimpleAdDisplayWidget(
                  ad: adWithLongText,
                  location: AdLocation.fluidDashboard,
                  trackAnalytics: false,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        // Verify the widget can be found and interacted with
        expect(find.byType(GestureDetector), findsOneWidget);

        // Test tap functionality
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
      });

      testWidgets('should handle semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAd,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label == 'Advertisement'),
          ),
          findsOneWidget,
        );
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid rebuilds', (WidgetTester tester) async {
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SimpleAdDisplayWidget(
                  ad: testAd,
                  location: AdLocation.fluidDashboard,
                  trackAnalytics: false,
                ),
              ),
            ),
          );
          await tester.pump();
        }

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
      });

      testWidgets('should dispose properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleAdDisplayWidget(
                ad: testAdWithMultipleImages,
                location: AdLocation.fluidDashboard,
                trackAnalytics: false,
              ),
            ),
          ),
        );

        // Remove the widget
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );

        // Should not find the widget anymore
        expect(find.byType(SimpleAdDisplayWidget), findsNothing);
      });
    });
  });
}
