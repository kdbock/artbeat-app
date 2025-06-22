// File: firebase_options.dart
// This file contains the Firebase options for the ARTbeat app.

import 'package:firebase_core/firebase_core.dart';

/// Default Firebase options for the ARTbeat app.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Return the Firebase options for the current platform
    return const FirebaseOptions(
      apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
      appId: '1:665020451634:android:70aaba9b305fa17b78652b',
      messagingSenderId: '665020451634',
      projectId: 'wordnerd-artbeat',
      storageBucket: 'wordnerd-artbeat.firebasestorage.app',
    );
  }
}
