import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

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
            'Could not determine your location. Please enter your ZIP code manually.');
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
      await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        fullName,
        zipCode: _zipCodeController.text.trim(),
      );

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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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

  void _navigateToPrivacy() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8C52FF),
                    Color(0xFF00BF63),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        // Back button and title row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Logo
                        Image.asset(
                          'assets/images/artbeat_logo.png',
                          height: 150,
                        ),
                        const SizedBox(height: 20),
                        // Form
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red.shade300),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style:
                                          TextStyle(color: Colors.red.shade900),
                                    ),
                                  ),
                                // Name Fields Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Card(
                                        elevation: 0,
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: TextFormField(
                                            controller: _firstNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'First Name',
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) =>
                                                (value?.isEmpty ?? true)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Card(
                                        elevation: 0,
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: TextFormField(
                                            controller: _lastNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Last Name',
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) =>
                                                (value?.isEmpty ?? true)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Email Field
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Email is required';
                                        }
                                        final emailRegex = RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                        if (!emailRegex.hasMatch(value!)) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // ZIP Code with Location
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _zipCodeController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'ZIP Code',
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'ZIP code is required';
                                              }
                                              if (!RegExp(r'^\d{5}(-\d{4})?$')
                                                  .hasMatch(value!)) {
                                                return 'Enter a valid ZIP code';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.my_location),
                                          onPressed: _isLoading
                                              ? null
                                              : _getZipCodeFromLocation,
                                          tooltip: 'Use my location',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password Fields
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Password is required';
                                        }
                                        if (value!.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        if (!value.contains(RegExp(r'[A-Z]'))) {
                                          return 'Include at least one uppercase letter';
                                        }
                                        if (!value.contains(RegExp(r'[0-9]'))) {
                                          return 'Include at least one number';
                                        }
                                        if (!value.contains(RegExp(
                                            r'[!@#$%^&*(),.?":{}|<>]'))) {
                                          return 'Include at least one special character';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Terms and Privacy Policy
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.white70,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreedToTerms = value ?? false;
                                          });
                                        },
                                        checkColor: Colors.white,
                                        fillColor:
                                            WidgetStateProperty.resolveWith(
                                                (states) {
                                          if (states.contains(
                                              WidgetState.selected)) {
                                            return const Color(0xFF8C52FF);
                                          }
                                          return Colors.white70;
                                        }),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: RichText(
                                            text: TextSpan(
                                              text: 'I agree to the ',
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                              children: [
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap =
                                                            _navigateToTerms,
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap =
                                                            _navigateToPrivacy,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Register Button
                                ElevatedButton(
                                  onPressed: (!_agreedToTerms || _isLoading)
                                      ? null
                                      : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF8C52FF),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF8C52FF)),
                                          ),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                // Login Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pushReplacementNamed(
                                              context, '/login'),
                                      child: const Text(
                                        'Log in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
