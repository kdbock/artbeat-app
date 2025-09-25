import 'dart:io';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
      appId: '1:665020451634:android:70aaba9b305fa17b78652b',
      messagingSenderId: '665020451634',
      projectId: 'wordnerd-artbeat',
    ),
  );

  final firestore = FirebaseFirestore.instance;
  const userId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43'; // Izzy's ID

  try {
    AppLogger.debug('🔍 Checking capture status for Izzy...');

    // Get all captures for this user
    final capturesSnapshot = await firestore
        .collection('captures')
        .where('userId', isEqualTo: userId)
        .get();

    AppLogger.analytics(
      '📊 Total captures found: ${capturesSnapshot.docs.length}',
    );

    // Count by status
    final statusCounts = <String, int>{};
    var totalExpectedXP = 0;

    for (final doc in capturesSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      if (status == 'approved') {
        totalExpectedXP += 50; // 50 XP per approved capture
      }
    }

    AppLogger.info('📈 Status breakdown:');
    statusCounts.forEach((status, countValue) {
      AppLogger.info('  $status: $countValue');
    });

    AppLogger.info('💰 Expected XP from approved captures: $totalExpectedXP');

    // Check current user XP
    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final currentXP = userData?['experiencePoints'] as int? ?? 0;

    AppLogger.performance('⚡ Current XP: $currentXP');
    AppLogger.error('❌ Missing XP: ${totalExpectedXP - currentXP}');

    // Show some sample captures with their status
    AppLogger.info('\n📝 Sample captures:');
    for (int i = 0; i < capturesSnapshot.docs.length && i < 5; i++) {
      final doc = capturesSnapshot.docs[i];
      final data = doc.data();
      AppLogger.info(
        '  ${doc.id}: ${data['status'] ?? 'pending'} - ${data['title'] ?? 'Untitled'}',
      );
    }
  } on Exception catch (e) {
    AppLogger.error('❌ Error: $e');
  }

  exit(0);
}
