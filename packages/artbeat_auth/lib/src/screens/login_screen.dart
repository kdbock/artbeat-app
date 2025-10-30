import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, UserService, UserModel;
import 'package:artbeat_core/src/utils/color_extensions.dart';
import '../constants/routes.dart';

/// Login screen with email/password authentication
class LoginScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

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

        try {
          // Clear any cached data first
          userService.clearUserCache();

          final userDoc = await userService.getUserById(user.uid);

          if (userDoc == null) {
            // Try to get additional user data from Firebase Auth
            final freshUser = FirebaseAuth.instance.currentUser;
            await freshUser?.reload(); // Refresh user data

            final createdUser = await userService.createNewUser(
              uid: user.uid,
              email: user.email ?? _emailController.text.trim(),
              displayName:
                  freshUser?.displayName ?? user.displayName ?? 'ARTbeat User',
            );

            if (createdUser == null) {
              throw Exception('Failed to create user profile in database');
            }

            // Verify creation with multiple attempts
            UserModel? verifiedDoc;
            for (int attempt = 1; attempt <= 3; attempt++) {
              await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
              userService.clearUserCache(); // Clear cache before each check
              verifiedDoc = await userService.getUserById(user.uid);
              if (verifiedDoc != null) {
                break;
              }
            }

            if (verifiedDoc == null) {
              throw Exception(
                'User profile creation could not be verified after multiple attempts',
              );
            }
          }
        } catch (e) {
          // Sign out the user since we couldn't create their profile
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create user profile: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return; // Exit early, don't navigate
        }
      }

      if (mounted) {
        // Check if we were pushed from another route that expects a return value
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // Return true to signal successful login
          navigator.pop(true);
        } else {
          // Normal navigation flow
          navigator.pushReplacementNamed(AuthRoutes.dashboard);
        }
      }
    } on FirebaseAuthException catch (e) {
      // debugPrint('FirebaseAuthException: [33m${e.message}[0m');
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

  /// Handle Google Sign-In button press
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final userCredential = await _authService.signInWithGoogle();

      if (mounted && userCredential.user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle Apple Sign-In button press
  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final userCredential = await _authService.signInWithApple();

      if (mounted && userCredential.user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Build social login buttons
  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Divider with "OR" text
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 24),

        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            key: const Key('google_sign_in_button'),
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
            label: const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Apple Sign-In Button (iOS only)
        if (Platform.isIOS)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              key: const Key('apple_sign_in_button'),
              onPressed: _isLoading ? null : _handleAppleSignIn,
              icon: const Icon(Icons.apple, color: Colors.black, size: 24),
              label: const Text(
                'Continue with Apple',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: ArtbeatColors.primaryPurple.withAlpha(120),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue your artistic journey',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ArtbeatColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
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
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      ArtbeatColors.primaryPurple,
                                      ArtbeatColors.primaryGreen,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushReplacementNamed(AuthRoutes.register),
                                    child: Center(
                                      child: Text(
                                        'Create Account',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      ArtbeatColors.primaryPurple,
                                      ArtbeatColors.primaryGreen,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(AuthRoutes.forgotPassword),
                                    child: Center(
                                      child: Text(
                                        'Forgot Password?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Add social login buttons
                        _buildSocialLoginButtons(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
