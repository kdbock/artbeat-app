import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestConfig {
  static Future<void> setupFirebaseForTesting() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'test-api-key', // Safe to use in tests
        appId: 'test-app-id', // Safe to use in tests
        messagingSenderId: 'test-sender-id', // Safe to use in tests
        projectId: 'test-project', // Safe to use in tests
        authDomain: 'test.firebaseapp.com', // Safe to use in tests
        storageBucket: 'test.appspot.com', // Safe to use in tests
      ),
    );
  }

  static String get emulatorHost =>
      Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static Future<void> configureFirebaseAuth() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  }

  static Future<void> configureFirebaseFirestore() async {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  }

  static Future<void> cleanupFirebaseData() async {
    final firestore = FirebaseFirestore.instance;
    await firestore.terminate();
    await firestore.clearPersistence();
  }
}
