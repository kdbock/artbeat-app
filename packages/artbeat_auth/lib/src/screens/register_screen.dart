import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; // Only import local AuthService
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, ArtbeatButton, ButtonVariant;
import 'package:artbeat_core/src/utils/location_utils.dart' show LocationUtils;
import 'package:artbeat_core/src/utils/color_extensions.dart';
import 'package:artbeat_core/artbeat_core.dart' show UserService;

/// Registration screen with email/password account creation
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Get zip code from device location
  Future<void> _getZipCodeFromLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final zipCode = await LocationUtils.getZipCodeFromCurrentPosition();
      if (zipCode.isNotEmpty) {
        setState(() {
          _zipCodeController.text = zipCode;
        });
      } else {
        _showErrorSnackBar(
          'Could not determine your location. Please enter your ZIP code manually.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error accessing location: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Handle register button press
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage =
            'Please agree to the Terms of Service and Privacy Policy';
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
      final zipCode = _zipCodeController.text.trim();

      // Register user and create profile in Firestore
      final userCredential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        fullName,
        zipCode: zipCode,
      );

      // Double-check that user document exists in Firestore
      final user = userCredential.user;
      if (user != null) {
        final userService = UserService();
        final userDoc = await userService.getUserById(user.uid);

        if (userDoc == null) {
          debugPrint(
            '⚠️ User document not found in Firestore. Creating it now...',
          );
          await userService.createNewUser(
            uid: user.uid,
            email: user.email ?? email,
            displayName: fullName,
            zipCode: zipCode,
          );
        } else {
          debugPrint('✅ User document confirmed in Firestore');
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      default:
        return 'Registration failed. Please try again. (${e.code})';
    }
  }

  void _navigateToTerms() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effective Date: June 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(
                        'Welcome to Artbeat Community, a platform provided by the Local Artbeat app to empower artists and connect them with patrons, peers, and sponsors. By using the Artbeat Community features, you agree to the following terms:\n',
                      ),
                      _TermsSection(
                        title: '1. Acceptance of Terms',
                        content:
                            'By accessing or using the Artbeat Community, you agree to comply with and be bound by these Terms of Service. If you do not agree, you may not use the platform.',
                      ),
                      _TermsSection(
                        title: '2. User Accounts',
                        content:
                            '• You must be at least 13 years old to create an account.\n• You are responsible for keeping your account credentials secure.',
                      ),
                      _TermsSection(
                        title: '3. Content Ownership',
                        content:
                            '• All artwork, comments, and media you upload remain your intellectual property.\n• You grant Artbeat Community a non-exclusive, royalty-free license to display your content within the app.',
                      ),
                      _TermsSection(
                        title: '4. Community Guidelines',
                        content:
                            '• Respect others. No hate speech, harassment, or plagiarism.\n• Do not post explicit or illegal content.\n• Feedback should be constructive and tagged appropriately.',
                      ),
                      _TermsSection(
                        title: '5. Gifting and Payments',
                        content:
                            '• Stripe handles all payment processing securely.\n• Artbeat Community is not liable for payment processing issues or chargebacks.\n• All transactions are final unless otherwise agreed upon by the sender and artist.',
                      ),
                      _TermsSection(
                        title: '6. Commissions and Sponsorships',
                        content:
                            '• Commissions are contracts between the artist and patron. Artbeat Community is not responsible for delivery, quality, or refunds.\n• Sponsored content must follow disclosure guidelines.',
                      ),
                      _TermsSection(
                        title: '7. Termination',
                        content:
                            'We reserve the right to suspend or terminate accounts that violate our policies or engage in abusive behavior.',
                      ),
                      _TermsSection(
                        title: '8. Changes to Terms',
                        content:
                            'We may modify these Terms of Service at any time. Continued use of the app means acceptance of the updated terms.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show terms and privacy dialog
  void _navigateToPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effective Date: June 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      _TermsSection(
                        title: '1. Information We Collect',
                        content:
                            '• Name, email, and avatar (at signup)\n• Artworks, comments, gifts, and interactions\n• Stripe account information (for artists receiving payments)\n• Usage data (app activity, crash logs)',
                      ),
                      _TermsSection(
                        title: '2. How We Use Your Information',
                        content:
                            '• To display your profile and shared artwork\n• To enable community features (chat, threads, gifts)\n• To process and track payments\n• To improve the platform\'s performance and security',
                      ),
                      _TermsSection(
                        title: '3. Data Sharing',
                        content:
                            '• We do not sell your data.\n• We use Stripe for payment processing. Stripe may collect and store information per their own policy.\n• We may share data with service providers (Firebase, analytics) strictly to provide core functionality.',
                      ),
                      _TermsSection(
                        title: '4. Data Retention',
                        content:
                            '• We keep user data as long as your account is active.\n• You may request account deletion at any time via settings or support.',
                      ),
                      _TermsSection(
                        title: '5. Security',
                        content:
                            '• Data is stored securely in Firebase using industry-standard encryption.\n• Payment data is handled exclusively by Stripe.',
                      ),
                      _TermsSection(
                        title: '6. Your Rights',
                        content:
                            '• You may access, correct, or delete your data at any time.\n• EU/California users may request additional protections under GDPR/CCPA.',
                      ),
                      _TermsSection(
                        title: '7. Contact Us',
                        content:
                            'For any questions or privacy-related requests, contact: support@localartbeat.app',
                      ),
                      _TermsSection(
                        title: '8. Changes to This Policy',
                        content:
                            'We may update this Privacy Policy periodically. Continued use of the platform indicates your acceptance of any changes.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: ArtbeatColors.primaryPurple,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
                    'Join ARTbeat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create your account to start your artistic journey',
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
                          Icon(
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
                          label: 'First Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ArtbeatInput(
                          controller: _lastNameController,
                          label: 'Last Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ArtbeatInput(
                          controller: _zipCodeController,
                          label: 'ZIP Code',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value.length != 5) {
                              return 'Invalid ZIP';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _getZipCodeFromLocation,
                        icon: const Icon(Icons.my_location),
                        color: ArtbeatColors.primaryPurple,
                        tooltip: 'Use current location',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ArtbeatInput(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ArtbeatInput(
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
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ArtbeatInput(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
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
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
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
                            text: 'I agree to the ',
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: ArtbeatColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _navigateToTerms,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
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
                  ArtbeatButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Already have an account? Log in',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ArtbeatColors.primaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
