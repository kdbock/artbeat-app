import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Fix XP points for Izzy Piel specifically
class IzzyXPFix extends StatefulWidget {
  const IzzyXPFix({Key? key}) : super(key: key);

  @override
  State<IzzyXPFix> createState() => _IzzyXPFixState();
}

class _IzzyXPFixState extends State<IzzyXPFix> {
  bool _isFixing = false;
  String _status = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _fixIzzyXP() async {
    if (_isFixing) return;

    setState(() {
      _isFixing = true;
      _status = 'Starting Izzy XP fix...';
    });

    try {
      // Use Izzy's specific user ID
      const izzyId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43';
      setState(() => _status = 'Getting Izzy\'s data...');

      final izzyDoc = await _firestore.collection('users').doc(izzyId).get();

      if (!izzyDoc.exists) {
        setState(() {
          _status = '❌ Could not find Izzy\'s user document';
          _isFixing = false;
        });
        return;
      }

      await _processIzzyXP(izzyDoc);
    } catch (e) {
      setState(() {
        _status = '❌ Error fixing Izzy XP: $e';
        _isFixing = false;
      });
    }
  }

  Future<void> _processIzzyXP(DocumentSnapshot izzyDoc) async {
    final izzyData = izzyDoc.data() as Map<String, dynamic>;
    final izzyId = izzyDoc.id;
    final currentXP = izzyData['experiencePoints'] as int? ?? 0;
    final currentLevel = izzyData['level'] as int? ?? 1;
    final storedCapturesCount = izzyData['capturesCount'] as int? ?? 0;

    if (!mounted) return;
    setState(
      () => _status =
          'Found ${izzyData['fullName']}\nCurrent XP: $currentXP\nStored Captures: $storedCapturesCount',
    );

    // Get Izzy's actual approved captures
    if (!mounted) return;
    setState(() => _status = 'Counting actual approved captures...');

    final capturesQuery = await _firestore
        .collection('captures')
        .where('userId', isEqualTo: izzyId)
        .where('status', isEqualTo: 'approved')
        .get();

    final actualApproved = capturesQuery.docs.length;
    final expectedXP = actualApproved * 50;
    final expectedLevel = (expectedXP / 1000).floor() + 1;

    if (!mounted) return;
    setState(
      () => _status =
          'Actual approved: $actualApproved\n'
          'Stored count: $storedCapturesCount\n'
          'Expected XP: $expectedXP\n'
          'Current XP: $currentXP\n'
          'Missing XP: ${expectedXP - currentXP}',
    );

    if (expectedXP <= currentXP) {
      if (!mounted) return;
      setState(() {
        _status =
            '✅ Izzy\'s XP is already correct!\n'
            'Approved captures: $actualApproved\n'
            'Current XP: $currentXP\n'
            'Expected XP: $expectedXP';
        _isFixing = false;
      });
      return;
    }

    // Direct update instead of incremental awards
    if (!mounted) return;
    setState(() => _status = 'Updating XP directly...');

    await _firestore.collection('users').doc(izzyId).update({
      'experiencePoints': expectedXP,
      'level': expectedLevel,
      'capturesCount': actualApproved, // Sync the captures count
      'lastXPGain': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() {
      _status =
          '✅ Izzy XP Fix Complete!\n'
          'Approved captures: $actualApproved\n'
          'XP: $currentXP → $expectedXP\n'
          'Level: $currentLevel → $expectedLevel\n'
          'XP gained: ${expectedXP - currentXP}';
      _isFixing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "izzy_xp_fix_fab",
      onPressed: _isFixing ? null : _fixIzzyXP,
      backgroundColor: _isFixing ? Colors.grey : Colors.blue,
      foregroundColor: Colors.white,
      label: Text(_isFixing ? 'Fixing Izzy...' : 'Fix Izzy XP'),
      icon: _isFixing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.person_pin),
      tooltip: _status.isEmpty ? 'Fix Izzy Piel\'s XP points' : _status,
    );
  }
}
