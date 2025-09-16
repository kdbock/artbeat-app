import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Manual XP fix for Izzy Piel
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('🔧 Manual Izzy XP Fix');
  AppLogger.info('====================\n');

  final firestore = FirebaseFirestore.instance;

  try {
    // Find Izzy by searching for her name
    AppLogger.info('1. Searching for Izzy Piel...');

    final usersSnapshot = await firestore.collection('users').get();
    DocumentSnapshot? izzyDoc;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final name = data?['displayName'] as String? ?? '';
      if (name.toLowerCase().contains('izzy') &&
          name.toLowerCase().contains('piel')) {
        izzyDoc = doc;
        break;
      }
    }

    if (izzyDoc == null) {
      AppLogger.error('❌ Could not find Izzy Piel in users collection');
      return;
    }

    final izzyData = izzyDoc.data() as Map<String, dynamic>;
    final izzyId = izzyDoc.id;
    AppLogger.info('✅ Found Izzy: ${izzyData['displayName']} (ID: $izzyId)');

    // Current stats
    final currentXP = izzyData['experiencePoints'] as int? ?? 0;
    final currentLevel = izzyData['level'] as int? ?? 1;
    AppLogger.info('   Current XP: $currentXP');
    AppLogger.info('   Current Level: $currentLevel');

    // Get approved captures
    AppLogger.info('\n2. Getting approved captures...');
    final capturesSnapshot = await firestore
        .collection('captures')
        .where('userId', isEqualTo: izzyId)
        .where('status', isEqualTo: 'approved')
        .get();

    final approvedCount = capturesSnapshot.docs.length;
    final expectedXP = approvedCount * 50;

    AppLogger.info('   Approved captures: $approvedCount');
    AppLogger.info('   Expected XP: $expectedXP');
    AppLogger.info('   Current XP: $currentXP');
    AppLogger.info('   Missing XP: ${expectedXP - currentXP}');

    if (expectedXP <= currentXP) {
      AppLogger.info('\n✅ Izzy\'s XP is already correct!');
      return;
    }

    // Fix XP
    AppLogger.info('\n3. Fixing XP...');
    final newLevel = (expectedXP / 1000).floor() + 1;

    await firestore.collection('users').doc(izzyId).update({
      'experiencePoints': expectedXP,
      'level': newLevel,
    });

    AppLogger.info('✅ XP Fix Complete!');
    AppLogger.info('   XP updated: $currentXP → $expectedXP');
    AppLogger.info('   Level updated: $currentLevel → $newLevel');
    AppLogger.info('   XP awarded: ${expectedXP - currentXP}');
  } catch (e) {
    AppLogger.error('❌ Error: $e');
  }

  AppLogger.info('\n🎯 Izzy should now have the correct XP points!');
}
