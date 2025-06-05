import 'package:firebase_core/firebase_core.dart';

/// SecureFirebaseConfig provides secure initialization for Firebase
class SecureFirebaseConfig {
  /// Initializes Firebase with proper options
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();

      // For detailed firebase initialization with options, import the generated options
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );

      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
