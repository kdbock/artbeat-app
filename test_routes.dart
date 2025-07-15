// Simple test to verify routes are defined
import 'package:flutter/material.dart';
import 'lib/app.dart';

void main() {
  final app = MyApp();

  // Test route generation
  final testRoutes = [
    '/community/dashboard',
    '/community/feed',
    '/community/posts',
    '/community/studios',
    '/community/gifts',
    '/community/portfolios',
    '/community/moderation',
    '/community/sponsorships',
    '/community/settings',
    '/notifications',
    '/profile',
    '/settings',
  ];

  print('Testing community navigation routes:');
  for (final route in testRoutes) {
    final routeResult = app.onGenerateRoute(RouteSettings(name: route));
    if (routeResult != null) {
      print('✅ Route "$route" - SUCCESS');
    } else {
      print('❌ Route "$route" - FAILED');
    }
  }

  print('\n🎉 Route testing complete!');
}
