import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXFpdz_5cJ8m4ZDgBb7kVx7PHxinwEkdA',
    appId: '1:665020451634:ios:2aa5cc17ac7d0dad78652b',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
    androidClientId:
        '665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4.apps.googleusercontent.com',
    iosBundleId: 'com.wordnerd.artbeat',
    appGroupId: 'group.H49R32NPY6.com.wordnerd.artbeat',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
    appId: '1:665020451634:android:70aaba9b305fa17b78652b',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXFpdz_5cJ8m4ZDgBb7kVx7PHxinwEkdA',
    appId: '1:665020451634:web:your-web-app-id',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
    authDomain: 'wordnerd-artbeat.firebaseapp.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXFpdz_5cJ8m4ZDgBb7kVx7PHxinwEkdA',
    appId: '1:665020451634:ios:2aa5cc17ac7d0dad78652b',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
    androidClientId:
        '665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4.apps.googleusercontent.com',
    iosBundleId: 'com.wordnerd.artbeat',
    appGroupId: 'group.H49R32NPY6.com.wordnerd.artbeat',
  );
}
