import 'dart:io';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
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
  final rewardsService = RewardsService();

  try {
    AppLogger.info('🔧 Starting XP fix for approved captures...');

    // Get all approved captures across all users
    final approvedCapturesSnapshot = await firestore
        .collection('captures')
        .where('status', isEqualTo: 'approved')
        .get();

    AppLogger.analytics(
      '📊 Found ${approvedCapturesSnapshot.docs.length} approved captures',
    );

    // Group by user to calculate missing XP
    final Map<String, List<String>> userCaptureIds = {};

    for (final doc in approvedCapturesSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      if (userId != null) {
        userCaptureIds[userId] ??= [];
        userCaptureIds[userId]!.add(doc.id);
      }
    }

    AppLogger.info(
      '👥 Processing ${userCaptureIds.length} users with approved captures',
    );

    int totalUsersFixed = 0;
    int totalXPAwarded = 0;

    // Process each user
    for (final entry in userCaptureIds.entries) {
      final userId = entry.key;
      final captureIds = entry.value;
      final expectedXP = captureIds.length * 50; // 50 XP per approved capture

      try {
        // Get current user XP
        final userDoc = await firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        final currentXP = userData?['experiencePoints'] as int? ?? 0;

        AppLogger.info('👤 User $userId:');
        AppLogger.info('  📸 Approved captures: ${captureIds.length}');
        AppLogger.performance('  ⚡ Current XP: $currentXP');
        AppLogger.info('  💰 Expected XP from captures: $expectedXP');

        // Calculate missing XP (assuming all current XP might be missing from captures)
        // We'll award the full expected amount to be safe
        if (expectedXP > 0) {
          // Award XP for each approved capture
          for (int i = 0; i < captureIds.length; i++) {
            await rewardsService.awardXP('art_capture_approved');

            // Small delay to avoid overwhelming the system
            if (i % 10 == 0 && i > 0) {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
          }

          totalUsersFixed++;
          totalXPAwarded += expectedXP;

          AppLogger.info('  ✅ Awarded $expectedXP XP');
        }
      } on Exception catch (userError) {
        AppLogger.error('  ❌ Error processing user $userId: $userError');
      }
    }

    AppLogger.info('\n🎉 XP Fix Complete!');
    AppLogger.info('📈 Summary:');
    AppLogger.info('  - Users processed: ${userCaptureIds.length}');
    AppLogger.info('  - Users fixed: $totalUsersFixed');
    AppLogger.info('  - Total XP awarded: $totalXPAwarded');
    AppLogger.info(
      '  - Average XP per user: ${totalUsersFixed > 0 ? (totalXPAwarded / totalUsersFixed).round() : 0}',
    );
  } on Exception catch (e) {
    AppLogger.error('❌ Error: $e');
  }

  exit(0);
}
