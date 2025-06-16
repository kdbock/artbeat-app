/// Defines the available filter types for the application
class FilterTypes {
  /// Filter by time period (today, this week, this month, etc.)
  static const String timePeriod = 'timePeriod';

  /// Filter by location (city, region, etc.)
  static const String location = 'location';

  /// Filter by category (painting, sculpture, etc.)
  static const String category = 'category';

  /// Filter by price range
  static const String priceRange = 'priceRange';

  /// Filter by artist
  static const String artist = 'artist';

  /// Filter by medium (oil, acrylic, etc.)
  static const String medium = 'medium';

  /// Filter by availability (available, sold, etc.)
  static const String availability = 'availability';

  /// Filter by rating (1-5 stars)
  static const String rating = 'rating';

  /// Private constructor to prevent instantiation
  const FilterTypes._();
}
