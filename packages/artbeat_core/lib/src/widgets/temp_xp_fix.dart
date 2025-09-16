import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

class TempXPFix extends StatefulWidget {
  const TempXPFix({Key? key}) : super(key: key);

  @override
  State<TempXPFix> createState() => _TempXPFixState();
}

class _TempXPFixState extends State<TempXPFix> {
  bool _isFixing = false;
  String _status = '';

  Future<void> _fixCurrentUserXP() async {
    if (_isFixing) return;

    setState(() {
      _isFixing = true;
      _status = 'Checking current user XP...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'No user logged in';
          _isFixing = false;
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final rewardsService = RewardsService();

      setState(() => _status = 'Getting approved captures...');

      // Get user's approved captures
      final approvedCapturesSnapshot = await firestore
          .collection('captures')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .get();

      final approvedCount = approvedCapturesSnapshot.docs.length;
      final expectedXP = approvedCount * 50;

      setState(
        () => _status =
            'Found $approvedCount approved captures. Expected XP: $expectedXP',
      );

      // Get current XP
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final currentXP = userData?['experiencePoints'] as int? ?? 0;

      setState(
        () => _status =
            'Current XP: $currentXP. Awarding XP for $approvedCount captures...',
      );

      // Award XP for each approved capture
      for (int i = 0; i < approvedCount; i++) {
        await rewardsService.awardXP('art_capture_approved');
        setState(() => _status = 'Awarding XP... ${i + 1}/$approvedCount');

        if (i % 5 == 0 && i > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }

      // Get final XP
      final finalUserDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final finalUserData = finalUserDoc.data();
      final finalXP = finalUserData?['experiencePoints'] as int? ?? 0;

      setState(() {
        _status =
            '✅ XP Fix Complete!\n'
            'Approved captures: $approvedCount\n'
            'XP awarded: ${finalXP - currentXP}\n'
            'Final XP: $finalXP';
        _isFixing = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "xp_fix_fab",
      onPressed: _isFixing ? null : _fixCurrentUserXP,
      backgroundColor: _isFixing ? Colors.grey : Colors.orange,
      icon: _isFixing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.auto_fix_high),
      label: Text(_isFixing ? 'Fixing XP...' : 'Fix My XP'),
      tooltip: _status.isEmpty
          ? 'Fix missing XP from approved captures'
          : _status,
    );
  }
}
