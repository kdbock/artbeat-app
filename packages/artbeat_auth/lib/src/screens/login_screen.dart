import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, UserService, UniversalHeader;
import 'package:artbeat_core/src/utils/color_extensions.dart';

/// Login screen with email/password authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      FirebaseAuth.instance.setLanguageCode('en');

      final userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Ensure user profile exists in Firestore using UserService
      final user = userCredential.user ?? FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userService = UserService();
        final userDoc = await userService.getUserById(user.uid);

        if (userDoc == null) {
          debugPrint(
            '⚠️ User authenticated but document not found in Firestore. Creating it now...',
          );

          // Try to get additional user data from Firebase Auth
          final freshUser = FirebaseAuth.instance.currentUser;
          await freshUser?.reload(); // Refresh user data

          await userService.createNewUser(
            uid: user.uid,
            email: user.email ?? _emailController.text.trim(),
            displayName:
                freshUser?.displayName ?? user.displayName ?? 'ARTbeat User',
          );

          // Verify creation
          final verifiedDoc = await userService.getUserById(user.uid);
          if (verifiedDoc == null) {
            debugPrint('❌ Failed to create user document after login');
          } else {
            debugPrint('✅ User document created successfully after login');
          }
        } else {
          debugPrint('✅ User document found in Firestore');
        }
      }

      if (mounted) {
        debugPrint('Login successful. Navigating to /dashboard.');

        // Check if we were pushed from another route that expects a return value
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // Return true to signal successful login
          navigator.pop(true);
        } else {
          // Normal navigation flow
          navigator.pushReplacementNamed('/dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: [33m${e.message}[0m');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalHeader(
        title: 'Login',
        showLogo: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlphaValue(0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withAlphaValue(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Animated logo
                        TweenAnimationBuilder(
                          duration: const Duration(seconds: 2),
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          builder: (context, double value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Image.asset(
                            'assets/images/artbeat_logo.png',
                            width: 320,
                            height: 320,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: ArtbeatColors.primaryPurple.withAlpha(120),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to continue your artistic journey',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ArtbeatColors.textSecondary),
                        ),
                        const SizedBox(height: 40),
                        ArtbeatInput(
                          key: const Key('emailField'),
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ArtbeatInput(
                          key: const Key('passwordField'),
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: ArtbeatColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                  top: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed('/register'),
                      child: const Text('Create Account'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
