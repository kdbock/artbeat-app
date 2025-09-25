import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Direct fix for Izzy Piel using her specific user ID
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('🔧 Direct Izzy XP Fix');
  AppLogger.info('====================\n');

  final firestore = FirebaseFirestore.instance;
  const izzyId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43';

  try {
    // Get current user data
    AppLogger.info('1. Getting Izzy\'s current data...');
    final userDoc = await firestore.collection('users').doc(izzyId).get();

    if (!userDoc.exists) {
      AppLogger.error('❌ User document not found');
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final currentXP = userData['experiencePoints'] as int? ?? 0;
    final currentLevel = userData['level'] as int? ?? 1;
    final capturesCount = userData['capturesCount'] as int? ?? 0;

    AppLogger.info('✅ Current data:');
    AppLogger.info('   Name: ${userData['fullName']}');
    AppLogger.info('   Current XP: $currentXP');
    AppLogger.info('   Current Level: $currentLevel');
    AppLogger.info('   Captures Count: $capturesCount');

    // Verify with actual approved captures
    AppLogger.info('\n2. Verifying approved captures...');
    final capturesSnapshot = await firestore
        .collection('captures')
        .where('userId', isEqualTo: izzyId)
        .where('status', isEqualTo: 'approved')
        .get();

    final actualApproved = capturesSnapshot.docs.length;
    AppLogger.info('   Actual approved captures: $actualApproved');
    AppLogger.info('   Document capturesCount: $capturesCount');

    // Use the actual approved count for XP calculation
    final expectedXP = actualApproved * 50;
    final newLevel = (expectedXP / 1000).floor() + 1;

    AppLogger.info('\n3. XP Calculation:');
    AppLogger.info('   Expected XP: $expectedXP ($actualApproved × 50)');
    AppLogger.info('   Expected Level: $newLevel');
    AppLogger.info('   XP to add: ${expectedXP - currentXP}');

    if (expectedXP <= currentXP) {
      AppLogger.info('\n✅ XP is already correct or higher!');
      return;
    }

    // Update the user document
    AppLogger.info('\n4. Updating user document...');
    await firestore.collection('users').doc(izzyId).update({
      'experiencePoints': expectedXP,
      'level': newLevel,
      'capturesCount': actualApproved, // Also sync this field
      'lastXPGain': FieldValue.serverTimestamp(),
    });

    AppLogger.info('✅ Update complete!');
    AppLogger.info('   XP: $currentXP → $expectedXP');
    AppLogger.info('   Level: $currentLevel → $newLevel');
    AppLogger.info('   Captures count synced: $actualApproved');

    // Verify the update
    AppLogger.info('\n5. Verifying update...');
    final updatedDoc = await firestore.collection('users').doc(izzyId).get();
    final updatedData = updatedDoc.data() as Map<String, dynamic>;

    AppLogger.info('✅ Verification:');
    AppLogger.info('   Final XP: ${updatedData['experiencePoints']}');
    AppLogger.info('   Final Level: ${updatedData['level']}');
    AppLogger.info('   Final Captures: ${updatedData['capturesCount']}');
  } on Exception catch (e, stackTrace) {
    AppLogger.error('❌ Error: $e');
    AppLogger.info('Stack trace: $stackTrace');
  }

  AppLogger.info('\n🎯 Izzy\'s XP has been corrected!');
}
