import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../widgets/auth_header.dart';
import '../constants/routes.dart';

/// Email verification screen that prompts users to verify their email address
/// Provides functionality to resend verification emails and check verification status
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _resendCooldown = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Start periodic check for email verification
  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  /// Check if email has been verified
  Future<void> _checkEmailVerification() async {
    await _user?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user?.emailVerified == true) {
      _timer?.cancel();
      if (mounted) {
        _showSuccessMessage();
        // Navigate to dashboard after successful verification
        Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
      }
    }
  }

  /// Send verification email
  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail || _user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _user!.sendEmailVerification();

      if (mounted) {
        _showSuccessSnackBar('Verification email sent to ${_user!.email}');
        _startResendCooldown();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(_getErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Failed to send verification email. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Start cooldown timer for resend button
  void _startResendCooldown() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60; // 60 seconds cooldown
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
        });

        if (_resendCooldown <= 0) {
          setState(() {
            _canResendEmail = true;
          });
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Get user-friendly error message
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'too-many-requests':
        return 'Too many requests. Please wait before trying again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'User account not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Show success message
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Skip verification and continue to dashboard
  void _skipVerification() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Email Verification?'),
        content: const Text(
          'You can verify your email later in account settings. '
          'Some features may be limited until your email is verified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AuthHeader(title: 'Verify Email', showBackButton: false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF46a8c3), // ARTbeat blue
              Color(0xFF2E8B9E), // Darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00bf63,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            size: 40,
                            color: Color(0xFF00bf63),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E8B9E),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'We\'ve sent a verification email to:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Email address
                        Text(
                          _user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E8B9E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Instructions
                        Text(
                          'Please check your email and click the verification link. '
                          'This page will automatically update once verified.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Resend button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00bf63),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _canResendEmail && !_isLoading
                                ? _sendVerificationEmail
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _canResendEmail
                                        ? 'Resend Verification Email'
                                        : 'Resend in ${_resendCooldown}s',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Skip button
                        TextButton(
                          onPressed: _skipVerification,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: Color(0xFF2E8B9E),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Help text
                        Text(
                          'Didn\'t receive the email? Check your spam folder or try resending.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
