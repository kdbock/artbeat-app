// ignore_for_file: do_not_use_environment

/// Application configuration loaded from build-time environment variables
///
/// To set these values during build, use --dart-define flags:
/// flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
/// flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();

  // Private constructor for singleton
  AppConfig._internal();

  // Factory constructor
  factory AppConfig() => _instance;

  // Build-time environment constants
  static const _googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const _stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const _firebaseRegion = String.fromEnvironment(
    'FIREBASE_REGION',
    defaultValue: 'us-central1',
  );
  static const _apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.artbeat.app',
  );
  static const _env = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Google Maps API Key
  /// Should be set via --dart-define during build
  String get googleMapsApiKey => _googleMapsKey;

  /// Stripe Publishable Key
  /// Should be set via --dart-define during build
  /// Use pk_test_* for testing, pk_live_* for production
  String get stripePublishableKey => _stripeKey;

  /// Firebase Region
  String get firebaseRegion => _firebaseRegion;

  /// API Base URL
  String get apiBaseUrl => _apiUrl;

  /// Environment (dev, staging, production)
  String get environment => _env;

  /// Check if running in production
  bool get isProduction => environment == 'production';

  /// Check if running in development
  bool get isDevelopment => environment == 'development';

  /// Validate that required configuration is present
  /// Call this during app initialization
  bool validate() {
    final issues = <String>[];

    if (googleMapsApiKey.isEmpty) {
      issues.add('GOOGLE_MAPS_API_KEY not configured');
    }

    if (stripePublishableKey.isEmpty) {
      issues.add('STRIPE_PUBLISHABLE_KEY not configured');
    } else if (isProduction && stripePublishableKey.startsWith('pk_test_')) {
      issues.add('WARNING: Using test Stripe key in production!');
    }

    if (issues.isNotEmpty) {
      // ignore: avoid_print
      print('⚠️  Configuration Issues:');
      for (final issue in issues) {
        // ignore: avoid_print
        print('   - $issue');
      }
      return false;
    }

    // ignore: avoid_print
    print('✅ All required configuration validated');
    return true;
  }

  /// Print current configuration (sanitized for logging)
  void printConfig() {
    // ignore: avoid_print
    print('📋 App Configuration:');
    // ignore: avoid_print
    print('   Environment: $environment');
    // ignore: avoid_print
    print('   API Base URL: $apiBaseUrl');
    // ignore: avoid_print
    print('   Firebase Region: $firebaseRegion');
    // ignore: avoid_print
    print('   Google Maps API Key: ${_sanitize(googleMapsApiKey)}');
    // ignore: avoid_print
    print('   Stripe Key: ${_sanitize(stripePublishableKey)}');
  }

  /// Sanitize sensitive values for logging
  String _sanitize(String value) {
    if (value.isEmpty) return '<not set>';
    if (value.length < 10) return '***';
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }
}
