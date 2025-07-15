import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/app.dart';

void main() {
  group('Navigation Audit Tests', () {
    testWidgets('FluidDashboardScreen navigation routes exist', (
      WidgetTester tester,
    ) async {
      // Create a test app
      final app = MyApp();

      // Test the key navigation routes that should exist
      final testRoutes = [
        '/search',
        '/artist/search',
        '/trending',
        '/local',
        '/auth',
        '/art-walk/my-walks',
        '/events',
        '/artist/onboarding',
        '/art-walk/dashboard',
        '/capture/dashboard',
        '/community/dashboard',
        '/artwork/featured',
        '/artist/dashboard',
        '/artist/public-profile',
        '/artist/artwork-detail',
        '/art-walk/map',
        '/art-walk/create',
        '/art-walk/list',
        '/art-walk/detail',
      ];

      // Test each route can be generated
      for (final route in testRoutes) {
        final settings = RouteSettings(name: route);
        final generatedRoute = app.onGenerateRoute(settings);

        expect(generatedRoute, isNotNull, reason: 'Route $route should exist');
        expect(
          generatedRoute.runtimeType.toString(),
          contains('MaterialPageRoute'),
          reason: 'Route $route should be a MaterialPageRoute',
        );
      }
    });

    testWidgets('FluidDashboardScreen navigation with arguments', (
      WidgetTester tester,
    ) async {
      final app = MyApp();

      // Test routes that require arguments
      final testRoutesWithArgs = [
        {
          'route': '/art-walk/detail',
          'arguments': {'walkId': 'test-walk-id'},
        },
        {
          'route': '/artist/public-profile',
          'arguments': {'artistId': 'test-artist-id'},
        },
        {
          'route': '/artist/artwork-detail',
          'arguments': {'artworkId': 'test-artwork-id'},
        },
      ];

      for (final testCase in testRoutesWithArgs) {
        final settings = RouteSettings(
          name: testCase['route'] as String,
          arguments: testCase['arguments'],
        );
        final generatedRoute = app.onGenerateRoute(settings);

        expect(
          generatedRoute,
          isNotNull,
          reason: 'Route ${testCase['route']} should exist with arguments',
        );
        expect(
          generatedRoute.runtimeType.toString(),
          contains('MaterialPageRoute'),
          reason: 'Route ${testCase['route']} should be a MaterialPageRoute',
        );
      }
    });
  });
}
