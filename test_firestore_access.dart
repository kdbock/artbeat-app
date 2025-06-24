// Simple test to verify Firestore access
// Run this with: flutter run test_firestore_access.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TestScreen());
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = 'Testing Firestore access...';

  @override
  void initState() {
    super.initState();
    _testFirestoreAccess();
  }

  Future<void> _testFirestoreAccess() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Test reading from publicArt collection
      setState(() {
        _status = 'Testing read access to publicArt collection...';
      });

      final snapshot = await firestore.collection('publicArt').limit(1).get();

      setState(() {
        _status =
            'Success! Found ${snapshot.docs.length} documents in publicArt collection.\n\n'
            'Now adding sample data...';
      });

      // Add sample data
      await _addSampleData();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _addSampleData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final sampleArt = {
        'userId': 'test_user_001',
        'title': 'Test Rainbow Mural',
        'description': 'A test mural for verification',
        'imageUrl': 'https://picsum.photos/400/300?test1',
        'artistName': 'Test Artist',
        'location': const GeoPoint(35.2651, -77.5866),
        'address': 'Test Address, NC',
        'tags': ['test', 'mural'],
        'artType': 'Mural',
        'isVerified': false,
        'viewCount': 0,
        'likeCount': 0,
        'usersFavorited': [],
        'createdAt': Timestamp.now(),
      };

      await firestore.collection('publicArt').add(sampleArt);

      setState(() {
        _status =
            'Success! Sample data added to publicArt collection.\n\n'
            'The app should now be able to load art pieces.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding sample data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Test')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            _status,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
