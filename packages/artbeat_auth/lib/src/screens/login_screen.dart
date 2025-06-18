import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, ArtbeatButton;
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

      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        debugPrint('Login successful. Navigating to /dashboard.');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
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
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue your artistic journey',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ArtbeatColors.textSecondary,
                    ),
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
                  ArtbeatButton(
                    key: const Key('loginButton'),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        key: const Key('registerButton'),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/register');
                        },
                        child: Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      TextButton(
                        key: const Key('forgotPasswordButton'),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
