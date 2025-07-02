import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_settings/artbeat_settings.dart';

// You can replace this with actual Firebase options for development
// Get Firebase configuration from ConfigService
final firebaseConfig = ConfigService.instance.firebaseConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await ConfigService.instance.initialize();
    final config = ConfigService.instance.firebaseConfig;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config['apiKey'] ?? '',
        appId: config['appId'] ?? '',
        messagingSenderId: config['messagingSenderId'] ?? '',
        projectId: config['projectId'] ?? '',
        storageBucket: config['storageBucket'] ?? '',
      ),
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const SettingsModuleApp());
}

class SettingsModuleApp extends StatelessWidget {
  const SettingsModuleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<UserService>(create: (_) => UserService()),
      ],
      child: MaterialApp(
        title: 'ARTbeat Settings Module',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SettingsModuleHome(),
      ),
    );
  }
}

class SettingsModuleHome extends StatelessWidget {
  const SettingsModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ARTbeat Settings Module')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Settings Module Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Navigation buttons to settings screens
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<SettingsScreen>(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
              child: const Text('All Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<AccountSettingsScreen>(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              ),
              child: const Text('Account Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<PrivacySettingsScreen>(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              ),
              child: const Text('Privacy Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<NotificationSettingsScreen>(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
              child: const Text('Notification Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<SecuritySettingsScreen>(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              ),
              child: const Text('Security Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<BlockedUsersScreen>(
                  builder: (_) => const BlockedUsersScreen(),
                ),
              ),
              child: const Text('Blocked Users'),
            ),
          ],
        ),
      ),
    );
  }
}
