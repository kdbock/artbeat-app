import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; // Only import local AuthService
import '../constants/routes.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatInput, ArtbeatButton;
import 'package:artbeat_core/src/utils/location_utils.dart' show LocationUtils;
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
  final _zipCodeController = TextEditingController();
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
          await userService.createNewUser(
            uid: user.uid,
            email: user.email ?? email,
            displayName: fullName,
            zipCode: zipCode,
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
                        'ARTbeat Terms of Service\n',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Effective Date: September 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(
                        'Last Updated: September 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      _TermsSection(
                        title: '1. Acceptance of Terms',
                        content:
                            'By accessing or using ARTbeat (the "Platform"), you agree to these Terms of Service ("Terms"). If you do not agree, you must not use ARTbeat. These Terms apply worldwide, subject to local laws where expressly required.',
                      ),
                      _TermsSection(
                        title: '2. Eligibility',
                        content:
                            'You must be at least 13 years old (or the minimum digital consent age in your country).\n\nIf you are under 18, you may use the Platform only with the consent of a parent or guardian.\n\nBy registering, you confirm that the information provided is accurate and up-to-date.',
                      ),
                      _TermsSection(
                        title: '3. Accounts & Registration',
                        content:
                            'Users must provide a valid name, email, and password during registration. ZIP code is optional and helps personalize content.\n\nYou are responsible for maintaining the security of your account, including enabling two-factor authentication where available.\n\nARTbeat may suspend or terminate accounts that violate these Terms.',
                      ),
                      _TermsSection(
                        title: '4. User Types & Roles',
                        content:
                            'Regular Users: May browse, follow, favorite, and engage with content.\n\nArtists: May upload artwork, manage profiles, sell work, host events, and access subscription tiers.\n\nGalleries: Manage multiple artists, exhibitions, and commissions.\n\nModerators/Admins: Enforce policies, moderate content, and manage the platform.',
                      ),
                      _TermsSection(
                        title: '5. User Content & Intellectual Property',
                        content:
                            'You retain ownership of artwork, captures, events, and other content you upload.\n\nBy posting, you grant ARTbeat a worldwide, non-exclusive, royalty-free license to store, display, distribute, and promote your content for Platform operation and marketing.\n\nContent must comply with community standards: no hate speech, harassment, nudity (outside artistic context), or unlawful materials.',
                      ),
                      _TermsSection(
                        title: '6. Payments & Subscriptions',
                        content:
                            'Payments are processed via Stripe.\n\nSubscription tiers, ads, events, and in-app purchases are billed in local currency where supported.\n\nRefunds are governed by event- or ad-specific refund policies.\n\nUsers must provide accurate billing information; fraudulent activity may result in termination.',
                      ),
                      _TermsSection(
                        title: '7. Advertising & Sponsorship',
                        content:
                            'Ads must comply with community and legal standards.\n\nARTbeat reserves the right to reject or remove ads at its discretion.\n\nAd performance analytics are aggregated and anonymized.',
                      ),
                      _TermsSection(
                        title: '8. Events & Ticketing',
                        content:
                            'Artists and galleries may create public or private events.\n\nTickets (free, paid, VIP) are sold through Stripe.\n\nRefunds depend on the event\'s Refund Policy; ARTbeat is not liable for disputes between buyers and event hosts.',
                      ),
                      _TermsSection(
                        title: '9. Messaging & Community Conduct',
                        content:
                            'Messaging is provided for personal and professional communication.\n\nUsers must not engage in spam, harassment, illegal solicitation, or unauthorized data collection.\n\nARTbeat may monitor reported messages for violations but does not read private messages by default.',
                      ),
                      _TermsSection(
                        title: '10. Location-Based Features',
                        content:
                            'Features such as Art Walks rely on GPS and mapping.\n\nYou consent to ARTbeat\'s use of your location data to provide navigation, recommendations, and achievements.\n\nARTbeat is not responsible for accidents, injuries, or damages during real-world activities.',
                      ),
                      _TermsSection(
                        title: '11. Privacy & Data Use',
                        content:
                            'ARTbeat complies with GDPR (EU), CCPA (California), and other applicable data protection laws.\n\nUsers may request data export or deletion via the Privacy Settings Screen.\n\nData may be transferred internationally; by using ARTbeat, you consent to such transfers.',
                      ),
                      _TermsSection(
                        title: '12. Moderation & Enforcement',
                        content:
                            'ARTbeat reserves the right to remove content, suspend accounts, or ban users at its discretion.\n\nUsers may appeal moderation actions by contacting support@localartbeat.app.\n\nRepeated violations may result in permanent account termination.',
                      ),
                      _TermsSection(
                        title: '13. Prohibited Uses',
                        content:
                            'You may not:\n\n• Upload unlawful, infringing, defamatory, or harmful content.\n• Circumvent security systems or attempt to reverse-engineer the app.\n• Use ARTbeat for unauthorized advertising or pyramid schemes.\n• Impersonate others or misrepresent affiliation.',
                      ),
                      _TermsSection(
                        title: '14. International Use',
                        content:
                            'The Platform is operated from the United States.\n\nUsers outside the US are responsible for compliance with local laws and regulations.\n\nCertain features (payments, ticketing, ads) may not be available in all jurisdictions.',
                      ),
                      _TermsSection(
                        title: '15. Limitation of Liability',
                        content:
                            'ARTbeat is provided "as is" and "as available".\n\nARTbeat is not liable for:\n• User disputes (artist-patron, buyer-seller).\n• Real-world accidents during events or art walks.\n• Payment processing errors outside ARTbeat\'s control.',
                      ),
                      _TermsSection(
                        title: '16. Indemnification',
                        content:
                            'You agree to indemnify and hold harmless ARTbeat, its affiliates, employees, and partners from claims, damages, or expenses arising from your use of the Platform.',
                      ),
                      _TermsSection(
                        title: '17. Termination',
                        content:
                            'You may terminate your account at any time via the Account Settings Screen.\n\nARTbeat may terminate accounts for violations of these Terms.\n\nCertain provisions (IP rights, liability, jurisdiction) survive termination.',
                      ),
                      _TermsSection(
                        title: '18. Governing Law & Dispute Resolution',
                        content:
                            'For US users: governed by the laws of North Carolina, United States.\n\nFor international users: governed by applicable mandatory local law, otherwise North Carolina law applies.\n\nDisputes shall be resolved through binding arbitration in the United States, unless prohibited by law.',
                      ),
                      _TermsSection(
                        title: '19. Changes to Terms',
                        content:
                            'ARTbeat may update these Terms from time to time. Notice will be provided via app notification or email. Continued use of the Platform constitutes acceptance of changes.',
                      ),
                      _TermsSection(
                        title: '20. Contact',
                        content:
                            'Questions or complaints may be directed to:\nARTbeat Support\nPO BOX 232 Kinston NC 28502\nsupport@localartbeat.app',
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
                        'ARTbeat Privacy Policy\n',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Effective Date: September 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(
                        'Last Updated: September 1, 2025\n',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      _TermsSection(
                        title: '1. Introduction',
                        content:
                            'Local ARTbeat ("ARTbeat", "we", "our", "us") values your privacy. This Privacy Policy explains how we collect, use, store, and share your personal data when you use the ARTbeat mobile apps, websites, APIs, and related services (the "Platform").\n\nBy using ARTbeat, you agree to the practices described here. If you do not agree, you must not use the Platform.',
                      ),
                      _TermsSection(
                        title: '2. Information We Collect',
                        content:
                            'a) Information You Provide:\n• Account Information: Name, email, password, ZIP/postal code.\n• Profile Information: Bio, profile photo, customization settings.\n• Artist/Gallery Information: Portfolio, subscription details, payout information.\n• Payment Information: Processed by Stripe; ARTbeat never stores full card details.\n• Content: Artwork, captures, events, ads, comments, messages.\n\nb) Information We Collect Automatically:\n• Device Information: Device type, operating system, app version, crash reports.\n• Usage Data: Logins, navigation, feature usage, interactions (favorites, likes, shares).\n• Location Data: GPS data when you use Art Walks, map features, or location-tagged captures.\n• Analytics Data: Firebase Analytics, engagement tracking, ad performance metrics.\n\nc) Information from Third Parties:\n• App Stores (Apple/Google): For app downloads, in-app purchases, refunds.\n• Social & Sharing Platforms: If you share content via external apps (e.g., Instagram, Facebook).\n• Payment Processors (Stripe): Payment confirmations, refunds, and chargeback details.',
                      ),
                      _TermsSection(
                        title: '3. How We Use Your Information',
                        content:
                            'We use data to:\n• Provide and improve ARTbeat features (profiles, artwork, events, ads, community).\n• Process payments, subscriptions, and refunds.\n• Enable GPS navigation and location-based discovery.\n• Send notifications (reminders, purchases, account alerts).\n• Moderate content and enforce policies.\n• Provide analytics to artists, galleries, and advertisers.\n• Ensure safety, prevent fraud, and comply with legal requirements.',
                      ),
                      _TermsSection(
                        title: '4. Sharing of Information',
                        content:
                            'We share your data only as needed:\n• With Service Providers: Stripe (payments), Firebase (storage, authentication, analytics).\n• With Other Users: Profile details, artwork, captures, events, ads, or comments you choose to make public.\n• For Moderation/Legal Compliance: To comply with DMCA, law enforcement, or platform security.\n• In Business Transfers: If ARTbeat undergoes a merger, acquisition, or asset sale.\n\nWe do not sell your personal information.',
                      ),
                      _TermsSection(
                        title: '5. Data Retention',
                        content:
                            '• Content remains until deleted by you or moderated.\n• Account data is retained while your account is active.\n• You may request deletion of your account and associated data at any time.\n• We may retain minimal information as required by law (e.g., payment records).',
                      ),
                      _TermsSection(
                        title: '6. International Data Transfers',
                        content:
                            '• Data is stored in Firebase\'s global infrastructure (primarily U.S.).\n• For EU/UK residents, transfers rely on Standard Contractual Clauses (SCCs).\n• By using ARTbeat, you consent to cross-border data transfers.',
                      ),
                      _TermsSection(
                        title: '7. Your Rights',
                        content:
                            'United States (CCPA/State Privacy Laws):\n• Right to know what personal data we collect.\n• Right to request deletion of your personal data.\n• Right to opt out of sale of personal data (we do not sell data).\n\nEU/EEA/UK (GDPR):\n• Right of access, rectification, and erasure.\n• Right to restrict or object to processing.\n• Right to data portability.\n• Right to withdraw consent at any time.\n• Right to lodge a complaint with your local Data Protection Authority.\n\nOther Regions:\n• We honor local legal rights where applicable.',
                      ),
                      _TermsSection(
                        title: '8. Security',
                        content:
                            '• End-to-end encryption for authentication and payments.\n• Two-factor authentication available for accounts.\n• Secure logging and XSS prevention built into services.\n• Despite protections, no system is 100% secure—users transmit data at their own risk.',
                      ),
                      _TermsSection(
                        title: '9. Children\'s Privacy',
                        content:
                            '• ARTbeat is not directed to children under 13.\n• If you are under 13, do not register.\n• Parents who believe their child has registered may request deletion via support@localartbeat.app.',
                      ),
                      _TermsSection(
                        title: '10. Changes to This Policy',
                        content:
                            'We may update this Privacy Policy. Updates will be posted with a new Effective Date, and we will notify users where legally required.',
                      ),
                      _TermsSection(
                        title: '11. Contact Us',
                        content:
                            'For questions or data requests:\nLocal ARTbeat, LLC\nPO BOX 232 Kinston, NC 28502\nEmail: support@localartbeat.app',
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
                            label: 'ZIP Code (Optional)',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            validator: (value) {
                              // Made optional for App Store compliance (Guideline 5.1.1)
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length != 5) {
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
                                  style: const TextStyle(
                                    color: ArtbeatColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _navigateToTerms,
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
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
                            : const Text('Register'),
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
                              'Already have an account? Log in',
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
