import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_auth/artbeat_auth.dart';

// Get Firebase configuration from ConfigService
final firebaseConfig = ConfigService.instance.firebaseConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await ConfigService.instance.initialize();
    final config = ConfigService.instance.firebaseConfig;
    // Check if Firebase is already initialized to avoid duplicate initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'] ?? '',
          appId: config['appId'] ?? '',
          messagingSenderId: config['messagingSenderId'] ?? '',
          projectId: config['projectId'] ?? '',
          storageBucket: config['storageBucket'] ?? '',
        ),
      );
    } else {
      AppLogger.firebase(
        'Firebase already initialized, using existing app instance',
      );
    }
    AppLogger.firebase('Firebase initialized successfully');
  } catch (e) {
    AppLogger.firebase('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const AuthModuleApp());
}

class AuthModuleApp extends StatelessWidget {
  const AuthModuleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<UserService>(create: (_) => UserService()),
        // Corrected Provider for AuthService
        Provider<AuthService>(
          create: (_) => AuthService(), // Removed userService parameter
        ),
      ],
      child: MaterialApp(
        title: 'ARTbeat Auth Module',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthModuleHome(),
      ),
    );
  }
}

class AuthModuleHome extends StatelessWidget {
  const AuthModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ARTbeat Auth Module')),
      body: Center(
        child: auth.currentUser != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome, ${auth.currentUser?.displayName ?? 'User'}!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => auth.signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Navigation buttons to the auth screens
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<LoginScreen>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text('Login Screen'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<RegisterScreen>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    child: const Text('Register Screen'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<ForgotPasswordScreen>(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: const Text('Forgot Password Screen'),
                  ),
                ],
              ),
      ),
    );
  }
}
