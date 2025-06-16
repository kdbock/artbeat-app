class AppConfig {
  static final Map<String, String> _config = {};

  static bool _isUsingPlaceholders = false;

  static bool get isUsingPlaceholders => _isUsingPlaceholders;

  static String get googleMapsApiKey => _config['googleMapsApiKey'] ?? '';
  static String get stripePublishableKey =>
      _config['stripePublishableKey'] ?? '';

  static String get(String key) {
    return _config[key] ?? '';
  }

  static void set(String key, String value) {
    _config[key] = value;
  }

  static void usePlaceholders(bool value) {
    _isUsingPlaceholders = value;
  }
}
