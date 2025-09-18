import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Enhanced Profile Menu - Comprehensive dropdown for user profile actions
///
/// This widget provides a complete profile management interface including:
/// - User profile information
/// - Profile management options
/// - Account settings
/// - Activity tracking
/// - Social features
/// - Subscription management
/// - Support and help
class EnhancedProfileMenu extends StatefulWidget {
  const EnhancedProfileMenu({Key? key}) : super(key: key);

  @override
  State<EnhancedProfileMenu> createState() => _EnhancedProfileMenuState();
}

class _EnhancedProfileMenuState extends State<EnhancedProfileMenu> {
  UserModel? _currentUser;
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with user info
            _buildUserHeader(),

            // Menu items
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Profile Management Section
                  _buildSectionHeader('Profile Management'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person,
                    title: 'View Profile',
                    subtitle: 'See your public profile',
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => _navigateToRoute('/profile'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your information',
                    color: ArtbeatColors.primaryGreen,
                    onTap: () => _navigateToRoute('/profile/edit'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.photo_camera,
                    title: 'Profile Picture',
                    subtitle: 'Change your profile photo',
                    color: ArtbeatColors.info,
                    onTap: () => _navigateToRoute('/profile/picture'),
                  ),

                  const SizedBox(height: 16),

                  // Activity & Social Section
                  _buildSectionHeader('Activity & Social'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.favorite,
                    title: 'Favorites',
                    subtitle: 'Your liked artwork and artists',
                    color: ArtbeatColors.error,
                    onTap: () => _navigateToRoute('/profile/favorites'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.people,
                    title: 'Connections',
                    subtitle: 'Followers and following',
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => _navigateToRoute('/profile/connections'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.history,
                    title: 'Activity History',
                    subtitle: 'Your recent actions',
                    color: ArtbeatColors.textSecondary,
                    onTap: () => _navigateToRoute('/profile/activity'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.analytics,
                    title: 'Profile Analytics',
                    subtitle: 'View your profile insights',
                    color: ArtbeatColors.warning,
                    onTap: () => _navigateToRoute('/profile/analytics'),
                  ),

                  const SizedBox(height: 16),

                  // Achievements & Rewards Section
                  _buildSectionHeader('Achievements & Rewards'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.emoji_events,
                    title: 'Achievements',
                    subtitle: 'Your badges and milestones',
                    color: ArtbeatColors.warning,
                    onTap: () => _navigateToRoute('/profile/achievements'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.card_giftcard,
                    title: 'Rewards',
                    subtitle: 'Redeem points and coupons',
                    color: ArtbeatColors.primaryGreen,
                    onTap: () => _navigateToRoute('/rewards'),
                  ),

                  const SizedBox(height: 16),

                  // Account & Settings Section
                  _buildSectionHeader('Account & Settings'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.settings,
                    title: 'Account Settings',
                    subtitle: 'Privacy, notifications, preferences',
                    color: ArtbeatColors.textSecondary,
                    onTap: () => _navigateToRoute('/settings'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    color: ArtbeatColors.info,
                    onTap: () => _navigateToRoute('/settings/privacy'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Customize your alerts',
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => _navigateToRoute('/settings/notifications'),
                  ),

                  const SizedBox(height: 16),

                  // Subscription & Billing Section
                  _buildSectionHeader('Subscription & Billing'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.star,
                    title: 'Subscription Plans',
                    subtitle: 'Upgrade or manage your plan',
                    color: ArtbeatColors.warning,
                    onTap: () => _navigateToRoute('/subscription/plans'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.payment,
                    title: 'Billing & Payments',
                    subtitle: 'Payment methods and history',
                    color: ArtbeatColors.primaryGreen,
                    onTap: () => _navigateToRoute('/billing'),
                  ),

                  const SizedBox(height: 16),

                  // Support & Help Section
                  _buildSectionHeader('Support & Help'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    color: ArtbeatColors.info,
                    onTap: () => _navigateToRoute('/help'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve ARTbeat',
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => _navigateToRoute('/feedback'),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.info,
                    title: 'About ARTbeat',
                    subtitle: 'App version and information',
                    color: ArtbeatColors.textSecondary,
                    onTap: () => _navigateToRoute('/about'),
                  ),

                  const SizedBox(height: 16),

                  // Sign Out Section
                  _buildSectionHeader('Account Actions'),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    color: ArtbeatColors.error,
                    onTap: () => _showSignOutDialog(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = user != null;

    if (!isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.account_circle,
              size: 64,
              color: ArtbeatColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Welcome to ARTbeat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to access your profile and personalized features',
              style: TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToRoute('/auth/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _navigateToRoute('/auth/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ArtbeatColors.primaryPurple,
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  (_currentUser != null &&
                      ImageUrlValidator.isValidImageUrl(
                        _currentUser!.profileImageUrl,
                      ))
                  ? Image.network(
                      _currentUser!.profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.fullName ?? user.displayName ?? 'ARTbeat User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? user.email ?? 'No email',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.7),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ArtbeatColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: ArtbeatColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRoute(String route) {
    Navigator.pop(context); // Close the profile menu first

    // Use a slight delay to ensure smooth navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        Navigator.pushNamed(context, route).catchError((error) {
          // Handle navigation errors gracefully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Feature coming soon: ${route.split('/').last}'),
              backgroundColor: ArtbeatColors.info,
            ),
          );
          return null; // Return a value to satisfy the catchError handler
        });
      }
    });
  }

  void _showSignOutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close profile menu
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: ArtbeatColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
