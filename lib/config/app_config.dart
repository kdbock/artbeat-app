/// Application configuration loaded from build-time environment variables
/// 
/// To set these values during build, use --dart-define flags:
/// flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
/// flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Google Maps API Key
  /// Should be set via --dart-define during build
  String get googleMapsApiKey => const String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: '',
      );

  /// Stripe Publishable Key
  /// Should be set via --dart-define during build
  /// Use pk_test_* for testing, pk_live_* for production
  String get stripePublishableKey => const String.fromEnvironment(
        'STRIPE_PUBLISHABLE_KEY',
        defaultValue: '',
      );

  /// Firebase Region
  String get firebaseRegion => const String.fromEnvironment(
        'FIREBASE_REGION',
        defaultValue: 'us-central1',
      );

  /// API Base URL
  String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.artbeat.app',
      );

  /// Environment (dev, staging, production)
  String get environment => const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      );

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
      print('⚠️  Configuration Issues:');
      for (final issue in issues) {
        print('   - $issue');
      }
      return false;
    }

    print('✅ All required configuration validated');
    return true;
  }

  /// Print current configuration (sanitized for logging)
  void printConfig() {
    print('📋 App Configuration:');
    print('   Environment: $environment');
    print('   API Base URL: $apiBaseUrl');
    print('   Firebase Region: $firebaseRegion');
    print('   Google Maps API Key: ${_sanitize(googleMapsApiKey)}');
    print('   Stripe Key: ${_sanitize(stripePublishableKey)}');
  }

  /// Sanitize sensitive values for logging
  String _sanitize(String value) {
    if (value.isEmpty) return '<not set>';
    if (value.length < 10) return '***';
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }
}
