#!/usr/bin/env dart

/// Migration script to add geo field to existing publicArt documents
/// This enables GeoFlutterFire geospatial queries for Instant Discovery Mode
///
/// Usage:
///   dart scripts/migrate_public_art_geo.dart
///
/// This script:
/// 1. Fetches all documents from the publicArt collection
/// 2. For each document with a location field, generates a geohash
/// 3. Updates the document with a geo field containing geohash and geopoint
///
/// The geo field structure:
/// {
///   "geo": {
///     "geohash": "9q8yy9mf8",
///     "geopoint": GeoPoint(37.7749, -122.4194)
///   }
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('🚀 Starting publicArt geo field migration...\n');

  // Initialize Firebase
  // Note: You'll need to configure Firebase for your project
  // This might require setting up firebase_options.dart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    print('Make sure you have firebase_options.dart configured');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final publicArtRef = firestore.collection('publicArt');

  try {
    // Fetch all publicArt documents
    print('📥 Fetching publicArt documents...');
    final snapshot = await publicArtRef.get();
    print('Found ${snapshot.docs.length} documents\n');

    if (snapshot.docs.isEmpty) {
      print('⚠️  No documents found in publicArt collection');
      print('This is normal if you haven\'t added any public art yet.');
      return;
    }

    int updated = 0;
    int skipped = 0;
    int errors = 0;

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        // Check if geo field already exists
        if (data.containsKey('geo')) {
          print('⏭️  Skipping ${doc.id} - geo field already exists');
          skipped++;
          continue;
        }

        // Check if location field exists
        if (!data.containsKey('location') || data['location'] == null) {
          print('⚠️  Skipping ${doc.id} - no location field');
          skipped++;
          continue;
        }

        final location = data['location'] as GeoPoint;
        final geohash = _generateGeohash(location.latitude, location.longitude);

        // Update document with geo field
        await doc.reference.update({
          'geo': {'geohash': geohash, 'geopoint': location},
        });

        print('✅ Updated ${doc.id} - ${data['title'] ?? 'Untitled'}');
        print('   Location: (${location.latitude}, ${location.longitude})');
        print('   Geohash: $geohash\n');
        updated++;
      } catch (e) {
        print('❌ Error updating ${doc.id}: $e\n');
        errors++;
      }
    }

    // Print summary
    print('\n${'=' * 50}');
    print('📊 Migration Summary');
    print('=' * 50);
    print('Total documents: ${snapshot.docs.length}');
    print('✅ Updated: $updated');
    print('⏭️  Skipped: $skipped');
    print('❌ Errors: $errors');
    print('=' * 50);

    if (updated > 0) {
      print('\n🎉 Migration completed successfully!');
      print('Instant Discovery Mode is now ready to use.');
    } else if (skipped == snapshot.docs.length) {
      print('\n✨ All documents already have geo fields!');
      print('No migration needed.');
    }
  } catch (e) {
    print('❌ Fatal error during migration: $e');
  }
}

/// Generate geohash for a location
/// Uses 9 characters precision (~4.8m x 4.8m)
String _generateGeohash(double latitude, double longitude) {
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
