// ignore_for_file: avoid_print

import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug script to check engagements in Firestore
void main() async {
  final firestore = FirebaseFirestore.instance;

  AppLogger.debug('🔍 Checking all engagements...');

  try {
    final engagements = await firestore
        .collection('engagements')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    AppLogger.analytics('📊 Total engagements found: ${engagements.docs.length}');

    for (final doc in engagements.docs) {
      final data = doc.data();
      AppLogger.info('---');
      AppLogger.info('ID: ${doc.id}');
      AppLogger.info('Content ID: ${data['contentId']}');
      AppLogger.info('Content Type: ${data['contentType']}');
      AppLogger.info('User ID: ${data['userId']}');
      AppLogger.info('Type: ${data['type']}');
      AppLogger.info('Created: ${data['createdAt']}');
      AppLogger.info('Metadata: ${data['metadata']}');
    }

    // Check specifically for ratings
    AppLogger.info('\n⭐ Checking ratings...');
    final ratings = await firestore
        .collection('engagements')
        .where('type', isEqualTo: 'rate')
        .get();

    AppLogger.analytics('📊 Total ratings found: ${ratings.docs.length}');

    // Check specifically for reviews
    AppLogger.info('\n📝 Checking reviews...');
    final reviews = await firestore
        .collection('engagements')
        .where('type', isEqualTo: 'review')
        .get();

    AppLogger.analytics('📊 Total reviews found: ${reviews.docs.length}');
  } catch (e) {
    AppLogger.error('❌ Error checking engagements: $e');
  }
}
