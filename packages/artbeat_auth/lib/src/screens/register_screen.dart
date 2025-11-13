import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../constants/routes.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, ArtbeatButton;
import 'package:artbeat_core/src/utils/color_extensions.dart';
import 'package:artbeat_core/artbeat_core.dart' show UserService;

/// Registration screen with email/password account creation
class RegisterScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle register button press
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'auth_register_error_agree_terms'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Register user and create profile in Firestore
      final userCredential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        fullName,
      );

      // Double-check that user document exists in Firestore
      final user = userCredential.user;
      if (user != null) {
        final userService = UserService();
        final userDoc = await userService.getUserById(user.uid);

        if (userDoc == null) {
          await userService.createNewUser(
            uid: user.uid,
            email: user.email ?? email,
            displayName: fullName,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AuthRoutes.dashboard);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'auth_register_error_unexpected'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Convert Firebase error code to user-friendly error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'auth_register_error_email_exists'.tr();
      case 'invalid-email':
        return 'auth_register_error_invalid_email'.tr();
      case 'weak-password':
        return 'auth_register_error_weak_password'.tr();
      default:
        return 'auth_register_error_failed'.tr(namedArgs: {'code': e.code});
    }
  }

  void _navigateToTerms() {
    Navigator.pushNamed(context, '/terms-of-service');
  }

  /// Show terms and privacy dialog
  void _navigateToPrivacyPolicy() {
    Navigator.pushNamed(context, '/privacy-policy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlphaValue(0.05),
                Colors.white,
                ArtbeatColors.accent2.withAlphaValue(0.05),
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
                    const SizedBox(height: 16),
                    // Animated logo
                    TweenAnimationBuilder(
                      duration: const Duration(seconds: 2),
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      builder: (context, double value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Image.asset(
                        'assets/images/artbeat_logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'auth_register_title'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: ArtbeatColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'auth_register_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.error.withAlphaValue(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: ArtbeatColors.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: ArtbeatColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Name fields in a row
                    Row(
                      children: [
                        Expanded(
                          child: ArtbeatInput(
                            controller: _firstNameController,
                            label: 'auth_register_first_name'.tr(),
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth_register_first_name_required'.tr();
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ArtbeatInput(
                            controller: _lastNameController,
                            label: 'auth_register_last_name'.tr(),
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth_register_last_name_required'.tr();
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ArtbeatInput(
                      controller: _emailController,
                      label: 'auth_register_email'.tr(),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth_register_email_required'.tr();
                        }
                        if (!value.contains('@')) {
                          return 'auth_register_email_invalid'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ArtbeatInput(
                      controller: _passwordController,
                      label: 'auth_register_password'.tr(),
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
                          return 'auth_register_password_required'.tr();
                        }
                        if (value.length < 8) {
                          return 'auth_register_password_min_length'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ArtbeatInput(
                      controller: _confirmPasswordController,
                      label: 'auth_register_confirm_password'.tr(),
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: ArtbeatColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth_register_confirm_password_required'.tr();
                        }
                        if (value != _passwordController.text) {
                          return 'auth_register_passwords_mismatch'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            activeColor: ArtbeatColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'auth_register_agree_prefix'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'auth_register_terms_link'.tr(),
                                  style: const TextStyle(
                                    color: ArtbeatColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _navigateToTerms,
                                ),
                                TextSpan(text: ' ${'auth_register_and'.tr()} '),
                                TextSpan(
                                  text: 'auth_register_privacy_link'.tr(),
                                  style: const TextStyle(
                                    color: ArtbeatColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _navigateToPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ArtbeatButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('auth_register_button'.tr()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 44,
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
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            AuthRoutes.login,
                          ),
                          child: Center(
                            child: Text(
                              'auth_register_login_link'.tr(),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
