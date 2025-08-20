/// Industry standard ad constants for ARTbeat Ads
class AdConstants {
  static const double userAdPricePerDay = 1.0;
  static const double artistAdPricePerDay = 1.0;
  static const double galleryAdPricePerDay = 1.0;
  static const int minAdDurationDays = 1;
  static const int maxAdDurationDays = 30;
  static const List<String> adLocations = [
    'Main Dashboard',
    'Art Walk Dashboard',
    'Capture Dashboard',
    'Community Dashboard',
    'Events Dashboard',
    'Community Feed',
  ];
  static const List<String> adTypes = ['Square (1:1)', 'Rectangle (2:1)'];
  static const int squareAdWidth = 300;
  static const int squareAdHeight = 300;
  static const int rectangleAdWidth = 400;
  static const int rectangleAdHeight = 200;
}
