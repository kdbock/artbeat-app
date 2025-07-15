/// Auth-related route constants for better maintainability and to prevent typos
class AuthRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Post-auth routes
  static const String dashboard = '/dashboard';
  static const String profileCreate = '/profile/create';

  // Helper method to validate if a route is an auth route
  static bool isAuthRoute(String route) {
    return [login, register, forgotPassword, profileCreate].contains(route);
  }

  // Helper method to get the default route after authentication
  static String getDefaultPostAuthRoute() => dashboard;

  // Helper method to get the route for users without profiles
  static String getProfileCreationRoute() => profileCreate;

  // Helper method to get the default unauthenticated route
  static String getDefaultUnauthenticatedRoute() => login;
}
