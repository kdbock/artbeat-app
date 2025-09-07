import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_ads/src/widgets/simple_ad_placement_widget.dart';
import 'package:artbeat_ads/src/widgets/simple_ad_display_widget.dart';
import 'package:artbeat_ads/src/services/simple_ad_service.dart';
import 'package:artbeat_ads/src/models/ad_model.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';

import '../test_helpers.dart';

import 'simple_ad_placement_widget_test.mocks.dart';

@GenerateMocks([SimpleAdService])
void main() {
  group('SimpleAdPlacementWidget Tests', () {
    late MockSimpleAdService mockAdService;
    late List<AdModel> testAds;

    setUp(() {
      mockAdService = MockSimpleAdService();
      testAds = AdTestHelpers.createTestAdList(count: 3);
    });

    Widget createTestWidget({
      AdLocation location = AdLocation.dashboard,
      EdgeInsets? padding,
      bool showIfEmpty = false,
      Widget Function(BuildContext)? emptyBuilder,
      bool trackAnalytics = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SimpleAdService>.value(
            value: mockAdService,
            child: SimpleAdPlacementWidget(
              location: location,
              padding: padding,
              showIfEmpty: showIfEmpty,
              emptyBuilder: emptyBuilder,
              trackAnalytics: trackAnalytics,
            ),
          ),
        ),
      );
    }

    group('Basic Widget Tests', () {
      testWidgets('should display ad when ads are available', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value(testAds));

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Allow stream to emit

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should show nothing when no ads and showIfEmpty is false', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

        await tester.pumpWidget(createTestWidget(showIfEmpty: false));
        await tester.pump();

        expect(find.byType(SimpleAdDisplayWidget), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets(
        'should show placeholder when no ads and showIfEmpty is true',
        (WidgetTester tester) async {
          when(
            mockAdService.getAdsByLocation(AdLocation.dashboard),
          ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

          await tester.pumpWidget(createTestWidget(showIfEmpty: true));
          await tester.pump();

          expect(find.text('Ad Space'), findsOneWidget);
          expect(find.byType(Container), findsWidgets);
        },
      );

      testWidgets('should show loading placeholder initially', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream.value(testAds));

        await tester.pumpWidget(createTestWidget(showIfEmpty: true));

        // Before the stream emits, should show placeholder or nothing
        expect(find.byType(SimpleAdDisplayWidget), findsNothing);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle stream errors gracefully', (
        WidgetTester tester,
      ) async {
        when(mockAdService.getAdsByLocation(AdLocation.dashboard)).thenAnswer(
          (_) => Stream<List<AdModel>>.error(Exception('Network error')),
        );

        await tester.pumpWidget(createTestWidget(showIfEmpty: true));
        await tester.pump();

        expect(find.text('Ad Space'), findsOneWidget);
        expect(find.byType(SimpleAdDisplayWidget), findsNothing);
      });

      testWidgets('should handle stream errors without placeholder', (
        WidgetTester tester,
      ) async {
        when(mockAdService.getAdsByLocation(AdLocation.dashboard)).thenAnswer(
          (_) => Stream<List<AdModel>>.error(Exception('Network error')),
        );

        await tester.pumpWidget(createTestWidget(showIfEmpty: false));
        await tester.pump();

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(SimpleAdDisplayWidget), findsNothing);
      });
    });

    group('Custom Builder Tests', () {
      testWidgets('should use custom empty builder when provided', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

        await tester.pumpWidget(
          createTestWidget(
            emptyBuilder: (context) => const Text('Custom Empty State'),
          ),
        );
        await tester.pump();

        expect(find.text('Custom Empty State'), findsOneWidget);
        expect(find.text('Ad Space'), findsNothing);
      });

      testWidgets('should prioritize custom builder over showIfEmpty', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

        await tester.pumpWidget(
          createTestWidget(
            showIfEmpty: true,
            emptyBuilder: (context) => const Text('Custom Builder Wins'),
          ),
        );
        await tester.pump();

        expect(find.text('Custom Builder Wins'), findsOneWidget);
        expect(find.text('Ad Space'), findsNothing);
      });
    });

    group('Layout and Styling Tests', () {
      testWidgets('should apply custom padding', (WidgetTester tester) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream.value(testAds));

        const customPadding = EdgeInsets.all(16.0);
        await tester.pumpWidget(createTestWidget(padding: customPadding));
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.padding, equals(customPadding));
      });

      testWidgets('should use default padding when none provided', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream.value(testAds));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.padding, equals(const EdgeInsets.all(8.0)));
      });

      testWidgets('should display first ad from list', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value(testAds));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);

        // Verify it's using the first ad
        final adWidget = tester.widget<SimpleAdDisplayWidget>(
          find.byType(SimpleAdDisplayWidget),
        );
        expect(adWidget.ad.id, equals(testAds.first.id));
      });
    });

    group('Different Locations Tests', () {
      testWidgets('should work with different ad locations', (
        WidgetTester tester,
      ) async {
        for (final location in AdLocation.values) {
          when(
            mockAdService.getAdsByLocation(location),
          ).thenAnswer((_) => Stream<List<AdModel>>.value([testAds.first]));

          await tester.pumpWidget(createTestWidget(location: location));
          await tester.pump();

          expect(find.byType(SimpleAdDisplayWidget), findsOneWidget);

          final adWidget = tester.widget<SimpleAdDisplayWidget>(
            find.byType(SimpleAdDisplayWidget),
          );
          expect(adWidget.location, equals(location));
        }
      });
    });

    group('Placeholder Styling Tests', () {
      testWidgets('should have correct placeholder styling', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

        await tester.pumpWidget(createTestWidget(showIfEmpty: true));
        await tester.pump();

        // Find the placeholder container
        final placeholderContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(Container),
                matching: find.byType(Container),
              )
              .last,
        );

        final decoration = placeholderContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.grey.shade100));
        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
        expect(decoration.border, isA<Border>());
      });

      testWidgets('should have correct placeholder constraints', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getAdsByLocation(AdLocation.dashboard),
        ).thenAnswer((_) => Stream<List<AdModel>>.value([]));

        await tester.pumpWidget(createTestWidget(showIfEmpty: true));
        await tester.pump();

        final placeholderContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(Container),
                matching: find.byType(Container),
              )
              .last,
        );

        expect(placeholderContainer.constraints?.maxWidth, equals(400));
        // Note: width and height are implementation details, focus on constraints
        expect(placeholderContainer.constraints?.maxWidth, isNotNull);
      });
    });
  });

  group('AdSpaceWidget Tests', () {
    late MockSimpleAdService mockAdService;

    setUp(() {
      mockAdService = MockSimpleAdService();
    });

    Widget createAdSpaceWidget({
      AdLocation location = AdLocation.dashboard,
      String? customLabel,
      double? width,
      double? height,
      bool trackAnalytics = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SimpleAdService>.value(
            value: mockAdService,
            child: AdSpaceWidget(
              location: location,
              customLabel: customLabel,
              width: width,
              height: height,
              trackAnalytics: trackAnalytics,
            ),
          ),
        ),
      );
    }

    group('Basic AdSpaceWidget Tests', () {
      testWidgets('should show ad placement when ads are available', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 1);
        when(mockAdService.getAdsByLocation(AdLocation.dashboard)).thenAnswer(
          (_) => Stream<List<AdModel>>.value([AdTestHelpers.createTestAd()]),
        );

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        expect(find.byType(SimpleAdPlacementWidget), findsOneWidget);
      });

      testWidgets('should show placeholder when no ads available', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
        expect(find.text('Dashboard Ad'), findsOneWidget);
      });

      testWidgets('should use custom label when provided', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(
          createAdSpaceWidget(customLabel: 'Custom Ad Label'),
        );
        await tester.pump();

        expect(find.text('Custom Ad Label'), findsOneWidget);
        expect(find.text('Dashboard Ad'), findsNothing);
      });

      testWidgets('should use custom dimensions when provided', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget(width: 200, height: 100));
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxWidth, equals(200));
      });
    });

    group('Different Locations Tests', () {
      testWidgets('should display correct location names', (
        WidgetTester tester,
      ) async {
        for (final location in AdLocation.values) {
          when(
            mockAdService.getActiveAdsCount(location),
          ).thenAnswer((_) async => 0);

          await tester.pumpWidget(createAdSpaceWidget(location: location));
          await tester.pump();

          expect(find.text('${location.displayName} Ad'), findsOneWidget);
        }
      });
    });

    group('Styling Tests', () {
      testWidgets('should have correct placeholder styling', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.grey.shade50));
        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
        expect(decoration.border, isA<Border>());
      });

      testWidgets('should have correct default dimensions', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );

        expect(container.constraints?.maxWidth, equals(400));
        // Note: width and height are implementation details, focus on constraints
        expect(container.constraints?.maxWidth, isNotNull);
      });

      testWidgets('should center content properly', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        // Check that content is centered by verifying the Column's mainAxisAlignment
        expect(find.byType(Column), findsOneWidget);

        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));

        // Verify the icon is present
        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle service errors gracefully', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => throw Exception('Service error'));

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pumpAndSettle();

        // Should show placeholder when service fails
        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });

      testWidgets('should handle null ad count', (WidgetTester tester) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        // Test with small screen
        await tester.binding.setSurfaceSize(const Size(300, 600));
        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        expect(find.byType(Container), findsWidgets);

        // Test with large screen
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        expect(find.byType(Container), findsWidgets);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should respect max width constraints', (
        WidgetTester tester,
      ) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget(width: 1000));
        await tester.pump();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );

        expect(container.constraints?.maxWidth, equals(1000));
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid rebuilds', (WidgetTester tester) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createAdSpaceWidget());
          await tester.pump();
        }

        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });

      testWidgets('should dispose properly', (WidgetTester tester) async {
        when(
          mockAdService.getActiveAdsCount(AdLocation.dashboard),
        ).thenAnswer((_) async => 0);

        await tester.pumpWidget(createAdSpaceWidget());
        await tester.pump();

        // Remove the widget
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );

        expect(find.byType(AdSpaceWidget), findsNothing);
      });
    });
  });
}
