// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug script to check engagements in Firestore
void main() async {
  final firestore = FirebaseFirestore.instance;

  print('🔍 Checking all engagements...');

  try {
    final engagements = await firestore
        .collection('engagements')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    print('📊 Total engagements found: ${engagements.docs.length}');

    for (final doc in engagements.docs) {
      final data = doc.data();
      print('---');
      print('ID: ${doc.id}');
      print('Content ID: ${data['contentId']}');
      print('Content Type: ${data['contentType']}');
      print('User ID: ${data['userId']}');
      print('Type: ${data['type']}');
      print('Created: ${data['createdAt']}');
      print('Metadata: ${data['metadata']}');
    }

    // Check specifically for ratings
    print('\n⭐ Checking ratings...');
    final ratings = await firestore
        .collection('engagements')
        .where('type', isEqualTo: 'rate')
        .get();

    print('📊 Total ratings found: ${ratings.docs.length}');

    // Check specifically for reviews
    print('\n📝 Checking reviews...');
    final reviews = await firestore
        .collection('engagements')
        .where('type', isEqualTo: 'review')
        .get();

    print('📊 Total reviews found: ${reviews.docs.length}');
  } catch (e) {
    print('❌ Error checking engagements: $e');
  }
}
