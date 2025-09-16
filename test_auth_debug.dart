import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Check current auth status
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    print('🔐 User is authenticated!');
    print('🔐 UID: ${user.uid}');
    print('🔐 Email: ${user.email}');
    print('🔐 Display Name: ${user.displayName}');
  } else {
    print('🔐 User is NOT authenticated');
    print('🔐 Attempting anonymous sign-in for testing...');

    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      print('🔐 Anonymous sign-in successful: ${credential.user?.uid}');
    } catch (e) {
      print('🔐 Anonymous sign-in failed: $e');
    }
  }
}
