class AppConfig {
  static final Map<String, String> _config = {
    'googleMapsApiKey': 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
    'stripePublishableKey': 'pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2',
    // Add other config values here
  };

  static bool _isUsingPlaceholders = false;
  
  static bool get isUsingPlaceholders => _isUsingPlaceholders;
  
  static String get googleMapsApiKey => _config['googleMapsApiKey'] ?? '';
  static String get stripePublishableKey => _config['stripePublishableKey'] ?? '';
  
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
