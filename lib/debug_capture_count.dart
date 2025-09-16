import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

/// Debug utility to fix capture counts for users
class CaptureCountFixer {
  static final UserService _userService = UserService();

  /// Fix capture count for a specific user
  static Future<void> fixUserCaptureCount(String userId) async {
    try {
      AppLogger.info('🔧 Fixing capture count for user: $userId');
      final success = await _userService.recalculateUserCaptureCount(userId);
      if (success) {
        AppLogger.info('✅ Successfully fixed capture count for user: $userId');
      } else {
        AppLogger.error('❌ Failed to fix capture count for user: $userId');
      }
    } catch (e) {
      AppLogger.error('❌ Error fixing capture count for user $userId: $e');
    }
  }

  /// Fix the specific user mentioned in the issue
  static Future<void> fixIzzyPielCaptureCount() async {
    const userId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43';
    await fixUserCaptureCount(userId);
  }

  /// Fix capture counts for all users (use with caution)
  static Future<void> fixAllUserCaptureCounts() async {
    try {
      AppLogger.info('🔧 Starting capture count fix for all users...');

      // This would need to be implemented to query all users
      // and fix their capture counts
      AppLogger.error('❌ Not implemented yet - would need to query all users');
    } catch (e) {
      AppLogger.error('❌ Error fixing all user capture counts: $e');
    }
  }
}

/// Debug screen to run capture count fixes
class CaptureCountDebugScreen extends StatefulWidget {
  const CaptureCountDebugScreen({super.key});

  @override
  State<CaptureCountDebugScreen> createState() =>
      _CaptureCountDebugScreenState();
}

class _CaptureCountDebugScreenState extends State<CaptureCountDebugScreen> {
  bool _isFixing = false;
  String _status = '';

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Capture Count Debug'),
        backgroundColor: Colors.red[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'User Izzy Piel has captures but capturesCount shows 0',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'User ID:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('EdH8MvWk4Ja6eoSZM59QtOaxEK43'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isFixing ? null : _fixIzzyPielCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isFixing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Fixing...'),
                      ],
                    )
                  : const Text('Fix Izzy Piel\'s Capture Count'),
            ),
            const SizedBox(height: 16),
            if (_status.isNotEmpty)
              Card(
                color: _status.contains('Successfully')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('Successfully')
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What this does:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Counts actual captures in Firestore'),
                    Text('• Updates the user\'s capturesCount field'),
                    Text('• Fixes display issues in profile and achievements'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Future<void> _fixIzzyPielCount() async {
    setState(() {
      _isFixing = true;
      _status = 'Fixing capture count...';
    });

    try {
      await CaptureCountFixer.fixIzzyPielCaptureCount();
      setState(() {
        _status = 'Successfully fixed Izzy Piel\'s capture count!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error fixing capture count: $e';
      });
    } finally {
      setState(() {
        _isFixing = false;
      });
    }
  }
}
