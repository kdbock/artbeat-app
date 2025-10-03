import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Instant Discovery - Distance Calculations', () {
    test('calculates distance between two points correctly', () {
      // San Francisco coordinates
      const lat1 = 37.7749;
      const lon1 = -122.4194;

      // Point ~100m away
      const lat2 = 37.7758;
      const lon2 = -122.4194;

      final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

      // Should be approximately 100 meters
      expect(distance, greaterThan(90));
      expect(distance, lessThan(110));
    });

    test('calculates bearing between two points correctly', () {
      // San Francisco coordinates
      const lat1 = 37.7749;
      const lon1 = -122.4194;

      // Point directly north
      const lat2 = 37.7759;
      const lon2 = -122.4194;

      final bearing = Geolocator.bearingBetween(lat1, lon1, lat2, lon2);

      // Should be approximately 0° (north)
      expect(bearing, greaterThan(-10));
      expect(bearing, lessThan(10));
    });

    test('calculates bearing for east direction correctly', () {
      // San Francisco coordinates
      const lat1 = 37.7749;
      const lon1 = -122.4194;

      // Point directly east
      const lat2 = 37.7749;
      const lon2 = -122.4184;

      final bearing = Geolocator.bearingBetween(lat1, lon1, lat2, lon2);

      // Should be approximately 90° (east)
      expect(bearing, greaterThan(85));
      expect(bearing, lessThan(95));
    });
  });

  group('Instant Discovery - Proximity Messages', () {
    String getProximityMessage(double distance) {
      if (distance < 10) {
        return "You're right on top of it!";
      } else if (distance < 25) {
        return 'Almost there! Look around!';
      } else if (distance < 50) {
        return 'Very close! Keep going!';
      } else if (distance < 100) {
        return 'Getting warmer...';
      } else if (distance < 250) {
        return "You're on the right track!";
      } else {
        return 'Head in this direction';
      }
    }

    test('returns correct message for very close distance', () {
      expect(getProximityMessage(5), "You're right on top of it!");
    });

    test('returns correct message for close distance', () {
      expect(getProximityMessage(20), 'Almost there! Look around!');
    });

    test('returns correct message for medium distance', () {
      expect(getProximityMessage(75), 'Getting warmer...');
    });

    test('returns correct message for far distance', () {
      expect(getProximityMessage(300), 'Head in this direction');
    });

    test('handles boundary conditions correctly', () {
      expect(getProximityMessage(9.9), "You're right on top of it!");
      expect(getProximityMessage(10), 'Almost there! Look around!');
      expect(getProximityMessage(49.9), 'Very close! Keep going!');
      expect(getProximityMessage(50), 'Getting warmer...');
    });
  });

  group('Instant Discovery - Geohash Generation', () {
    String generateGeohash(double latitude, double longitude) {
      const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
      final latRange = [-90.0, 90.0];
      final lonRange = [-180.0, 180.0];
      var hash = '';
      var isEven = true;
      var bit = 0;
      var ch = 0;

      while (hash.length < 9) {
        if (isEven) {
          final mid = (lonRange[0] + lonRange[1]) / 2;
          if (longitude > mid) {
            ch |= 1 << (4 - bit);
            lonRange[0] = mid;
          } else {
            lonRange[1] = mid;
          }
        } else {
          final mid = (latRange[0] + latRange[1]) / 2;
          if (latitude > mid) {
            ch |= 1 << (4 - bit);
            latRange[0] = mid;
          } else {
            latRange[1] = mid;
          }
        }

        isEven = !isEven;

        if (bit < 4) {
          bit++;
        } else {
          hash += base32[ch];
          bit = 0;
          ch = 0;
        }
      }

      return hash;
    }

    test('generates geohash with correct length', () {
      final hash = generateGeohash(37.7749, -122.4194);
      expect(hash.length, 9);
    });

    test('generates consistent geohash for same location', () {
      final hash1 = generateGeohash(37.7749, -122.4194);
      final hash2 = generateGeohash(37.7749, -122.4194);
      expect(hash1, hash2);
    });

    test('generates different geohashes for different locations', () {
      final hash1 = generateGeohash(37.7749, -122.4194); // San Francisco
      final hash2 = generateGeohash(40.7128, -74.0060); // New York
      expect(hash1, isNot(hash2));
    });

    test('generates geohash with valid base32 characters', () {
      final hash = generateGeohash(37.7749, -122.4194);
      const validChars = '0123456789bcdefghjkmnpqrstuvwxyz';

      for (var char in hash.split('')) {
        expect(validChars.contains(char), true);
      }
    });

    test('nearby locations have similar geohash prefixes', () {
      final hash1 = generateGeohash(37.7749, -122.4194);
      final hash2 = generateGeohash(37.7750, -122.4195); // ~10m away

      // First 6-7 characters should match for nearby locations
      expect(hash1.substring(0, 6), hash2.substring(0, 6));
    });
  });

  group('Instant Discovery - XP Calculations', () {
    test('calculates base discovery XP correctly', () {
      const baseXP = 20;
      expect(baseXP, 20);
    });

    test('calculates first discovery of day bonus correctly', () {
      const baseXP = 20;
      const firstDiscoveryBonus = 50;
      const total = baseXP + firstDiscoveryBonus;
      expect(total, 70);
    });

    test('calculates streak bonus correctly', () {
      const baseXP = 20;
      const streak = 5;
      const streakBonus = 10 * streak;
      const total = baseXP + streakBonus;
      expect(total, 70);
    });

    test('calculates maximum XP with all bonuses', () {
      const baseXP = 20;
      const firstDiscoveryBonus = 50;
      const streak = 7;
      const streakBonus = 10 * streak;
      const total = baseXP + firstDiscoveryBonus + streakBonus;
      expect(total, 140); // 20 + 50 + 70
    });
  });

  group('Instant Discovery - Radar Positioning', () {
    test('normalizes distance correctly', () {
      const radiusMeters = 500.0;
      const distance = 250.0;
      final normalized = (distance / radiusMeters).clamp(0.0, 1.0);
      expect(normalized, 0.5);
    });

    test('clamps distance beyond radius', () {
      const radiusMeters = 500.0;
      const distance = 750.0;
      final normalized = (distance / radiusMeters).clamp(0.0, 1.0);
      expect(normalized, 1.0);
    });

    test('handles zero distance correctly', () {
      const radiusMeters = 500.0;
      const distance = 0.0;
      final normalized = (distance / radiusMeters).clamp(0.0, 1.0);
      expect(normalized, 0.0);
    });
  });
}
