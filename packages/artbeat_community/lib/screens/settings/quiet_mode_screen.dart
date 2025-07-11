import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

class QuietModeScreen extends StatefulWidget {
  const QuietModeScreen({super.key});

  @override
  _QuietModeScreenState createState() => _QuietModeScreenState();
}

class _QuietModeScreenState extends State<QuietModeScreen> {
  bool _isQuietModeEnabled = false;
  String _quietModeMessage = "";

  @override
  void initState() {
    super.initState();
    _loadQuietModeSettings();
  }

  Future<void> _loadQuietModeSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _isQuietModeEnabled =
              (userDoc.data()?['quietModeEnabled'] as bool?) ?? false;
          _quietModeMessage =
              (userDoc.data()?['quietModeMessage'] as String?) ?? "";
        });
      }
    }
  }

  Future<void> _updateQuietModeSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'quietModeEnabled': _isQuietModeEnabled,
        'quietModeMessage': _quietModeMessage,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(title: 'Quiet Mode', showLogo: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Quiet Mode'),
              value: _isQuietModeEnabled,
              onChanged: (value) {
                setState(() {
                  _isQuietModeEnabled = value;
                });
                _updateQuietModeSettings();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Quiet Mode Message',
                hintText: 'Leave a message for your followers',
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _quietModeMessage = value;
                });
              },
              onSubmitted: (value) {
                _updateQuietModeSettings();
              },
              controller: TextEditingController(text: _quietModeMessage),
            ),
          ],
        ),
      ),
    );
  }
}
