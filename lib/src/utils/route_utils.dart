import 'package:flutter/material.dart';

/// Utility class for route generation and navigation
class RouteUtils {
  /// Creates a standard route with the default transition
  static Route<dynamic> createRoute({required Widget child}) => MaterialPageRoute(builder: (_) => child);

  /// Creates a route with the main app layout (includes drawer, app bar, etc.)
  static Route<dynamic> createMainLayoutRoute({required Widget child}) => MaterialPageRoute(builder: (_) => child);

  /// Creates a simple route without app layout
  static Route<dynamic> createSimpleRoute({required Widget child}) => MaterialPageRoute(builder: (_) => child);

  /// Creates a route for the "not found" screen
  static Route<dynamic> createNotFoundRoute() => MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
    );

  /// Helper to get arguments from route settings in a type-safe way
  static T? getArgument<T>(RouteSettings settings) => settings.arguments as T?;
}
