import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/utils/location_utils.dart';

void main() {
  group('NC ZIP Code Database Tests', () {
    final db = NCZipCodeDatabase();

    test('ZIP code database initializes correctly', () {
      expect(db, isNotNull);
      expect(db.getAllRegions().length, equals(6));
      expect(db.getAllZipCodes().length, greaterThan(100));
    });

    test('Region lookup works correctly', () {
      expect(db.getRegionByName('Mountain')!.name, equals('Mountain'));
      expect(db.getRegionByName('Foothills')!.name, equals('Foothills'));
      expect(db.getRegionByName('Piedmont')!.name, equals('Piedmont'));
      expect(db.getRegionByName('Sandhills')!.name, equals('Sandhills'));
      expect(
          db.getRegionByName('Coastal Plain')!.name, equals('Coastal Plain'));
      expect(db.getRegionByName('Coastal')!.name, equals('Coastal'));
    });

    test('County lookup works correctly', () {
      final asheCounty = db
          .getRegionByName('Mountain')!
          .counties
          .firstWhere((county) => county.name == 'Ashe County');
      expect(asheCounty.name, equals('Ashe County'));
      expect(asheCounty.zipCodes.contains('28617'), isTrue);
    });

    test('ZIP code to region lookup works correctly', () {
      expect(db.getInfoForZipCode('28801')!.region, equals('Mountain'));
      expect(db.getInfoForZipCode('28801')!.county, equals('Buncombe County'));

      expect(db.getInfoForZipCode('28655')!.region, equals('Foothills'));
      expect(db.getInfoForZipCode('28655')!.county, equals('Burke County'));

      expect(db.getInfoForZipCode('27713')!.region, equals('Piedmont'));
      expect(db.getInfoForZipCode('27713')!.county, equals('Durham County'));
    });

    test('Invalid ZIP code returns null', () {
      expect(db.getInfoForZipCode('00000'), isNull);
    });

    test('ZIP code validation works correctly', () {
      expect(db.isNCZipCode('28801'), isTrue); // Asheville
      expect(db.isNCZipCode('28655'), isTrue); // Morganton
      expect(db.isNCZipCode('90210'), isFalse); // Beverly Hills
    });

    test('Get ZIP codes by region works correctly', () {
      final mountainZipCodes = db.getZipCodesByRegion('Mountain');
      expect(mountainZipCodes.contains('28801'), isTrue);
      expect(mountainZipCodes.contains('28804'), isTrue);

      final coastalZipCodes = db.getZipCodesByRegion('Coastal');
      expect(coastalZipCodes.contains('28401'), isTrue);
    });
  });

  group('Location Utils Tests', () {
    test('Region lookup works correctly', () {
      expect(LocationUtils.isLocationInNC('28801'), isTrue);
      expect(LocationUtils.getRegionForZipCode('28801'), equals('Mountain'));
      expect(LocationUtils.getCountyForZipCode('28801'),
          equals('Buncombe County'));
    });

    test('ZIP code extraction works correctly', () {
      expect(
          LocationUtils.extractZipCodeFromAddress(
              '123 Main St, Asheville NC 28801'),
          equals('28801'));
      expect(
          LocationUtils.extractZipCodeFromAddress('No ZIP code here'), isNull);
    });

    test('ZIP code region check works correctly', () {
      expect(LocationUtils.isZipCodeInRegion('28801', 'Mountain'), isTrue);
      expect(LocationUtils.isZipCodeInRegion('28801', 'Coastal'), isFalse);
    });

    test('Find region from text works correctly', () {
      expect(
          LocationUtils.findRegionFromText(
              'I live in 28801 which is in Asheville'),
          equals('Mountain'));
      expect(LocationUtils.findRegionFromText('No ZIP code here'), isNull);
    });
  });
}
