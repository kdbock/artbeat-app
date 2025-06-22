import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS) {
      return ios;
    } else if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzH_pJ_I2U_rkC4OBKVasjjJMus3LtSH0',
    appId: '1:665020451634:ios:2aa5cc17ac7d0dad78652b',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
    androidClientId: '665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4.apps.googleusercontent.com',
    iosBundleId: 'com.wordnerd.artbeat',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
    appId: '1:665020451634:android:70aaba9b305fa17b78652b',
    messagingSenderId: '665020451634',
    projectId: 'wordnerd-artbeat',
    storageBucket: 'wordnerd-artbeat.firebasestorage.app',
  );

}