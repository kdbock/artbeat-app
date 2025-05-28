/// Model representing a North Carolina region with counties and ZIP codes
class NCRegionModel {
  final String name;
  final List<NCCountyModel> counties;

  NCRegionModel({
    required this.name,
    required this.counties,
  });

  /// Converts this model to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'counties': counties.map((county) => county.toMap()).toList(),
    };
  }

  /// Creates a model from map data
  factory NCRegionModel.fromMap(Map<String, dynamic> map) {
    return NCRegionModel(
      name: map['name'],
      counties: (map['counties'] as List)
          .map((county) => NCCountyModel.fromMap(county))
          .toList(),
    );
  }

  @override
  String toString() => 'NCRegionModel(name: $name, counties: $counties)';
}

/// Model representing a North Carolina county with ZIP codes
class NCCountyModel {
  final String name;
  final List<String> zipCodes;

  NCCountyModel({
    required this.name,
    required this.zipCodes,
  });

  /// Converts this model to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zipCodes': zipCodes,
    };
  }

  /// Creates a model from map data
  factory NCCountyModel.fromMap(Map<String, dynamic> map) {
    return NCCountyModel(
      name: map['county'],
      zipCodes: List<String>.from(map['zip_codes']),
    );
  }

  @override
  String toString() => 'NCCountyModel(name: $name, zipCodes: $zipCodes)';
}

/// Simple model for storing ZIP code information
class NCZipCodeInfo {
  final String zipCode;
  final String county;
  final String region;

  NCZipCodeInfo({
    required this.zipCode,
    required this.county,
    required this.region,
  });

  @override
  String toString() =>
      'NCZipCodeInfo(zipCode: $zipCode, county: $county, region: $region)';
}
