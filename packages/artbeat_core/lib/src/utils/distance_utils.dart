/// Distance utility functions for converting between miles and kilometers
/// and formatting distance values based on user preferences
class DistanceUtils {
  // Conversion constants
  static const double _milesPerKilometer = 0.621371;
  static const double _kilometersPerMile = 1.60934;
  static const double _metersPerMile = 1609.34;
  static const double _metersPerKilometer = 1000.0;

  /// Convert meters to miles
  static double metersToMiles(double meters) {
    return meters / _metersPerMile;
  }

  /// Convert meters to kilometers
  static double metersToKilometers(double meters) {
    return meters / _metersPerKilometer;
  }

  /// Convert miles to meters
  static double milesToMeters(double miles) {
    return miles * _metersPerMile;
  }

  /// Convert kilometers to meters
  static double kilometersToMeters(double kilometers) {
    return kilometers * _metersPerKilometer;
  }

  /// Convert miles to kilometers
  static double milesToKilometers(double miles) {
    return miles * _kilometersPerMile;
  }

  /// Convert kilometers to miles
  static double kilometersToMiles(double kilometers) {
    return kilometers * _milesPerKilometer;
  }

  /// Format distance based on user's preferred unit
  /// Returns a formatted string like "2.5 mi" or "4.0 km"
  static String formatDistance(
    double meters, {
    required String unit, // 'miles' or 'kilometers'
    int decimalPlaces = 1,
    bool includeUnit = true,
  }) {
    double distance;
    String unitAbbr;

    if (unit == 'miles') {
      distance = metersToMiles(meters);
      unitAbbr = 'mi';
    } else {
      distance = metersToKilometers(meters);
      unitAbbr = 'km';
    }

    final formattedDistance = distance.toStringAsFixed(decimalPlaces);
    return includeUnit ? '$formattedDistance $unitAbbr' : formattedDistance;
  }

  /// Get distance in user's preferred unit (returns the numeric value)
  static double getDistanceInPreferredUnit(double meters, String unit) {
    return unit == 'miles' ? metersToMiles(meters) : metersToKilometers(meters);
  }

  /// Get distance filter radius in meters based on user's preferred unit
  /// For example: if user sets 50 miles, convert to meters for distance calculations
  static double getFilterRadiusInMeters(double distance, String unit) {
    return unit == 'miles'
        ? milesToMeters(distance)
        : kilometersToMeters(distance);
  }

  /// Get appropriate default search radius based on unit preference
  static double getDefaultSearchRadius(String unit) {
    // Default to 62 miles (100km) for broader coverage
    return unit == 'miles' ? 62.0 : 100.0;
  }

  /// Get unit abbreviation
  static String getUnitAbbreviation(String unit) {
    return unit == 'miles' ? 'mi' : 'km';
  }

  /// Get unit display name
  static String getUnitDisplayName(String unit) {
    return unit == 'miles' ? 'Miles' : 'Kilometers';
  }

  /// Validate distance unit
  static bool isValidDistanceUnit(String unit) {
    return unit == 'miles' || unit == 'kilometers';
  }

  /// Get reasonable distance ranges for sliders based on unit
  static Map<String, double> getDistanceSliderRange(String unit) {
    if (unit == 'miles') {
      return {
        'min': 0.5,
        'max': 100.0,
        'default': 62.0, // ~100km
      };
    } else {
      return {'min': 1.0, 'max': 160.0, 'default': 100.0};
    }
  }
}
