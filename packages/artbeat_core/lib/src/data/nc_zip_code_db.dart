// NC Zip Code Database

class NCZipCodeModel {
  final String zipCode;
  final String region;
  final String county;
  final double latitude;
  final double longitude;

  NCZipCodeModel({
    required this.zipCode,
    required this.region,
    required this.county,
    required this.latitude,
    required this.longitude,
  });
}

class NCRegionInfo {
  final String name;
  final String county;
  final List<String> cities;

  NCRegionInfo({
    required this.name,
    required this.county,
    required this.cities,
  });
}

class NCZipCodeDatabase {
  // Singleton instance
  static final NCZipCodeDatabase _instance = NCZipCodeDatabase._internal();
  factory NCZipCodeDatabase() => _instance;
  NCZipCodeDatabase._internal();

  // Constants for regions
  static const String MOUNTAIN = 'Mountain';
  static const String PIEDMONT = 'Piedmont';
  static const String COASTAL = 'Coastal';

  // Map NC zip codes to regions
  final Map<String, String> zipToRegion = {
    '28801': MOUNTAIN, '28806': MOUNTAIN, '28804': MOUNTAIN, // Asheville
    '27701': PIEDMONT, '27707': PIEDMONT, '27713': PIEDMONT, // Durham
    '27601': PIEDMONT, '27603': PIEDMONT, '27608': PIEDMONT, // Raleigh
    '28403': COASTAL, '28405': COASTAL, '28412': COASTAL, // Wilmington  
    // More zip codes would be added here
  };

  // Map regions to counties
  final Map<String, List<String>> regionToCounties = {
    MOUNTAIN: ['Buncombe', 'Henderson', 'Madison', 'Haywood', 'Transylvania'],
    PIEDMONT: ['Wake', 'Durham', 'Orange', 'Chatham', 'Guilford', 'Mecklenburg'],
    COASTAL: ['New Hanover', 'Brunswick', 'Pender', 'Onslow', 'Carteret'],
  };

  // Check if a zip code is in NC
  bool isNCZipCode(String zipCode) {
    return zipToRegion.containsKey(zipCode);
  }

  // Get region for a zip code
  String getRegionForZipCode(String zipCode) {
    return zipToRegion[zipCode] ?? 'Unknown';
  }

  // Get info for a zip code
  NCZipCodeModel getInfoForZipCode(String zipCode) {
    final region = getRegionForZipCode(zipCode);
    
    // Determine county based on zip code (simplified example)
    String county = 'Unknown';
    if (region == MOUNTAIN) {
      if (['28801', '28806', '28804'].contains(zipCode)) county = 'Buncombe';
    } else if (region == PIEDMONT) {
      if (['27701', '27707', '27713'].contains(zipCode)) county = 'Durham';
      if (['27601', '27603', '27608'].contains(zipCode)) county = 'Wake';
    } else if (region == COASTAL) {
      if (['28403', '28405', '28412'].contains(zipCode)) county = 'New Hanover';
    }
    
    // Determine lat/long (simplified example)
    double lat = 35.5951;
    double lng = -82.5515;
    
    return NCZipCodeModel(
      zipCode: zipCode,
      region: region,
      county: county,
      latitude: lat,
      longitude: lng,
    );
  }

  // Get zip codes for a region
  List<String> getZipCodesByRegion(String region) {
    return zipToRegion.entries
        .where((entry) => entry.value == region)
        .map((entry) => entry.key)
        .toList();
  }
  
  // Get region by name
  NCRegionInfo getRegionByName(String regionName) {
    if (!regionToCounties.containsKey(regionName)) {
      return NCRegionInfo(name: 'Unknown', county: 'Unknown', cities: []);
    }
    
    List<String> counties = regionToCounties[regionName] ?? [];
    
    // Example cities by region
    List<String> cities = [];
    if (regionName == MOUNTAIN) {
      cities = ['Asheville', 'Hendersonville', 'Black Mountain'];
    } else if (regionName == PIEDMONT) {
      cities = ['Raleigh', 'Durham', 'Chapel Hill', 'Charlotte'];
    } else if (regionName == COASTAL) {
      cities = ['Wilmington', 'Jacksonville', 'Morehead City'];
    }
    
    return NCRegionInfo(
      name: regionName,
      county: counties.isNotEmpty ? counties.first : 'Unknown',
      cities: cities,
    );
  }
  
  // Get all regions
  List<String> getAllRegions() {
    return [MOUNTAIN, PIEDMONT, COASTAL];
  }
}
