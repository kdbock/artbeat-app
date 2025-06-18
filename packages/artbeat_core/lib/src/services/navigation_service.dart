import 'package:flutter/material.dart';

/// Service to handle navigation between modules
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a named route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Replace current route with a named route
  Future<dynamic> navigateToReplace(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Pop to a specific route
  void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Go back one screen
  void goBack() {
    navigatorKey.currentState!.pop();
  }

  /// Go back with result
  void goBackWithResult(dynamic result) {
    navigatorKey.currentState!.pop(result);
  }
}
