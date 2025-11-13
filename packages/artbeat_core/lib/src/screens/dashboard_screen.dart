import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'artbeat_dashboard_screen.dart';
import 'dashboard/artist_dashboard.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/onboarding_dashboard.dart';

/// Unified Dashboard Entry Point
///
/// Intelligently routes users to role-appropriate dashboards
/// with progressive onboarding for new users.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = await userService.getCurrentUserModel();

      if (mounted) {
        setState(() {
          _userModel = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingDashboard();
    }

    if (_error != null) {
      return _ErrorDashboard(error: _error!, onRetry: _loadUserProfile);
    }

    // Route to appropriate dashboard based on user state and role
    return _routeToDashboard(_userModel);
  }

  Widget _routeToDashboard(UserModel? user) {
    // New users get onboarding experience
    if (user == null || _isNewUser(user)) {
      return OnboardingDashboard(
        user:
            user ??
            UserModel(
              id: '',
              email: '',
              username: 'New User',
              fullName: 'New User',
              createdAt: DateTime.now(),
            ),
      );
    }

    // Route based on primary role
    final userType = user.userType;
    switch (userType) {
      case 'artist':
        return ArtistDashboard(user: user);
      case 'business': // gallery
        return AdminDashboard(user: user);
      case 'admin':
        return AdminDashboard(user: user);
      case 'moderator':
        return AdminDashboard(user: user);
      default:
        // Default to user dashboard for general users
        return const ArtbeatDashboardScreen();
    }
  }

  bool _isNewUser(UserModel user) {
    // If onboarding is already completed, they're not a new user
    if (user.onboardingCompleted) {
      return false;
    }
    
    // Consider user new if account created within last 24 hours
    // or if they have very low activity (0 XP and no captures)
    final isVeryRecent = DateTime.now().difference(user.createdAt).inHours < 24;
    final hasNoActivity = user.experiencePoints == 0 && user.captures.isEmpty;

    return isVeryRecent || hasNoActivity;
  }
}

/// Loading state for dashboard
class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.palette_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'dashboard_loading'.tr(),
              style: ArtbeatTypography.textTheme.headlineMedium!.copyWith(
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'dashboard_preparing_experience'.tr(),
              style: ArtbeatTypography.textTheme.bodyMedium!.copyWith(
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtbeatColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state for dashboard
class _ErrorDashboard extends StatelessWidget {
  const _ErrorDashboard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ArtbeatColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: ArtbeatColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'dashboard_error_title'.tr(),
                style: ArtbeatTypography.textTheme.headlineMedium!.copyWith(
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'dashboard_error_message'.tr(),
                style: ArtbeatTypography.textTheme.bodyMedium!.copyWith(
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('dashboard_retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
