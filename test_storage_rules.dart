// Quick test to verify storage access
// Run this in the terminal: flutter run --target=test_storage_rules.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: StorageTestScreen());
  }
}

class StorageTestScreen extends StatefulWidget {
  @override
  _StorageTestScreenState createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  String _status = 'Ready to test';

  Future<void> testStorageAccess() async {
    setState(() {
      _status = 'Testing storage access...';
    });

    try {
      // First check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: User not authenticated. Please log in first.';
        });
        return;
      }

      // Create a test file
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_upload.txt');
      await testFile.writeAsString(
        'Test file content for storage rules validation',
      );

      // Test different storage paths
      final storage = FirebaseStorage.instance;

      // Test 1: Profile image upload
      try {
        final profileRef = storage.ref().child(
          'profile_images/${user.uid}/test.jpg',
        );
        await profileRef.putFile(testFile);
        setState(() {
          _status = '✅ Profile image upload: SUCCESS\n$_status';
        });
      } catch (e) {
        setState(() {
          _status = '❌ Profile image upload: FAILED - $e\n$_status';
        });
      }

      // Test 2: Artwork image upload
      try {
        final artworkRef = storage.ref().child(
          'artwork_images/${user.uid}/test_artwork/test.jpg',
        );
        await artworkRef.putFile(testFile);
        setState(() {
          _status = '✅ Artwork image upload: SUCCESS\n$_status';
        });
      } catch (e) {
        setState(() {
          _status = '❌ Artwork image upload: FAILED - $e\n$_status';
        });
      }

      // Test 3: Artist image upload
      try {
        final artistRef = storage.ref().child(
          'artist_images/${user.uid}/portfolio/test.jpg',
        );
        await artistRef.putFile(testFile);
        setState(() {
          _status = '✅ Artist image upload: SUCCESS\n$_status';
        });
      } catch (e) {
        setState(() {
          _status = '❌ Artist image upload: FAILED - $e\n$_status';
        });
      }

      // Test 4: Feedback image upload
      try {
        final feedbackRef = storage.ref().child(
          'feedback_images/${user.uid}/test.jpg',
        );
        await feedbackRef.putFile(testFile);
        setState(() {
          _status = '✅ Feedback image upload: SUCCESS\n$_status';
        });
      } catch (e) {
        setState(() {
          _status = '❌ Feedback image upload: FAILED - $e\n$_status';
        });
      }

      // Clean up
      await testFile.delete();

      setState(() {
        _status = '🎉 Storage test completed!\n$_status';
      });
    } catch (e) {
      setState(() {
        _status = 'Error during storage test: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Storage Rules Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Current user: ${FirebaseAuth.instance.currentUser?.email ?? "Not logged in"}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: testStorageAccess,
              child: Text('Test Storage Access'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
