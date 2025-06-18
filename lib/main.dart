// filepath: /Users/kristybock/updated_artbeat_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureFirebaseConfig.initializeFirebase();
  runApp(MyApp());
}
