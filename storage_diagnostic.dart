import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

class StorageDiagnosticScreen extends StatefulWidget {
  @override
  _StorageDiagnosticScreenState createState() => _StorageDiagnosticScreenState();
}

class _StorageDiagnosticScreenState extends State<StorageDiagnosticScreen> {
  List<String> _logs = [];
  bool _testing = false;

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _testing = true;
      _logs.clear();
    });

    try {
      _log('=== Firebase Storage Diagnostic ===');
      
      // Check Firebase initialization
      _log('Checking Firebase initialization...');
      if (Firebase.apps.isEmpty) {
        _log('ERROR: No Firebase apps initialized');
        return;
      }
      
      final app = Firebase.app();
      _log('Firebase app: ${app.name}, project: ${app.options.projectId}');
      
      // Check Firebase Auth
      _log('Checking Firebase Auth...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('ERROR: User not authenticated');
        return;
      }
      _log('User authenticated: ${user.uid}');
      _log('User email: ${user.email}');
      _log('User email verified: ${user.emailVerified}');
      
      // Check Firebase Storage
      _log('Checking Firebase Storage...');
      final storage = FirebaseStorage.instance;
      _log('Storage bucket: ${storage.bucket}');
      _log('Storage app: ${storage.app.name}');
      
      // Try to list root files (should work if Storage is enabled)
      _log('Testing root directory access...');
      try {
        final listResult = await storage.ref().listAll();
        _log('SUCCESS: Root directory accessible, found ${listResult.items.length} items');
        if (listResult.items.isNotEmpty) {
          _log('Sample items: ${listResult.items.take(3).map((item) => item.name).join(', ')}');
        }
      } catch (e) {
        _log('ERROR: Cannot access root directory: $e');
        
        // This suggests Storage is not enabled or configured
        if (e.toString().contains('object-not-found')) {
          _log('DIAGNOSIS: Firebase Storage appears to be not enabled for this project');
          _log('SOLUTION: Enable Firebase Storage in the Firebase Console');
        }
      }
      
      // Try different bucket configurations
      _log('Testing different bucket configurations...');
      final buckets = [
        'wordnerd-artbeat.appspot.com',
        'gs://wordnerd-artbeat.appspot.com',
      ];
      
      for (final bucket in buckets) {
        try {
          _log('Testing bucket: $bucket');
          final storageInstance = FirebaseStorage.instanceFor(bucket: bucket);
          final testRef = storageInstance.ref('test-file.txt');
          _log('Reference created for $bucket: ${testRef.fullPath}');
          
          // Try to get metadata (this works even if file doesn't exist if bucket exists)
          try {
            await testRef.getMetadata();
            _log('SUCCESS: Bucket $bucket is accessible');
          } catch (metaError) {
            if (metaError.toString().contains('object-not-found')) {
              _log('SUCCESS: Bucket $bucket exists (file not found is expected)');
            } else {
              _log('ERROR: Bucket $bucket not accessible: $metaError');
            }
          }
        } catch (e) {
          _log('ERROR: Cannot access bucket $bucket: $e');
        }
      }
      
      // Test simple file creation
      _log('Testing simple file creation...');
      try {
        final testRef = storage.ref('diagnostic-test.txt');
        final testData = 'Test data ${DateTime.now().millisecondsSinceEpoch}';
        await testRef.putString(testData);
        _log('SUCCESS: Created test file');
        
        // Try to read it back
        final downloadUrl = await testRef.getDownloadURL();
        _log('SUCCESS: Got download URL: $downloadUrl');
        
        // Clean up
        await testRef.delete();
        _log('SUCCESS: Cleaned up test file');
        
      } catch (e) {
        _log('ERROR: Cannot create test file: $e');
        
        if (e.toString().contains('object-not-found')) {
          _log('DIAGNOSIS: Firebase Storage bucket does not exist or is not configured');
        } else if (e.toString().contains('permission-denied')) {
          _log('DIAGNOSIS: Storage rules deny write access');
        } else if (e.toString().contains('unauthenticated')) {
          _log('DIAGNOSIS: User authentication issue');
        }
      }
      
      _log('=== Diagnostic Complete ===');
      
    } catch (e) {
      _log('FATAL ERROR: $e');
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Diagnostic'),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _testing ? null : _runDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_testing)
            LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color? color;
                if (log.contains('ERROR') || log.contains('FATAL')) {
                  color = Colors.red;
                } else if (log.contains('SUCCESS')) {
                  color = Colors.green;
                } else if (log.contains('DIAGNOSIS') || log.contains('SOLUTION')) {
                  color = Colors.orange;
                }
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureFirebaseConfig.initializeFirebase();
  runApp(MaterialApp(
    home: StorageDiagnosticScreen(),
  ));
}
