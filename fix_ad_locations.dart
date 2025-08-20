import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to fix ad location values in Firestore
/// This script updates ads with invalid location values to use valid AdLocation enum indices
void main() async {
  await Firebase.initializeApp();
  await fixAdLocations();
}

Future<void> fixAdLocations() async {
  final firestore = FirebaseFirestore.instance;

  print('🔧 Starting ad location fix...');

  // Fix ads collection
  await fixCollection(firestore, 'ads');

  // Fix artist_approved_ads collection
  await fixCollection(firestore, 'artist_approved_ads');

  print('✅ Ad location fix completed!');
}

Future<void> fixCollection(
  FirebaseFirestore firestore,
  String collectionName,
) async {
  print('📁 Fixing collection: $collectionName');

  final snapshot = await firestore.collection(collectionName).get();

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final currentLocation = data['location'];

    // If location is null, invalid, or outside valid range (0-5)
    if (currentLocation == null ||
        currentLocation is! int ||
        currentLocation < 0 ||
        currentLocation > 5) {
      // Set to dashboard (0) as default
      await doc.reference.update({
        'location': 0, // AdLocation.dashboard
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Fixed ad ${doc.id}: location $currentLocation -> 0 (dashboard)');
    }
  }

  print('📊 Finished fixing $collectionName');
}
