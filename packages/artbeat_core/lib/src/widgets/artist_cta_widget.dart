import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/artbeat_colors.dart';

/// "Are you an artist?" Call-to-Action widget
///
/// This widget appears at the bottom of dashboard screens to encourage
/// non-artist users to explore subscription options and become artists.
/// It's the entry point to the subscription process.
class ArtistCTAWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showDismiss;

  const ArtistCTAWidget({super.key, this.onTap, this.showDismiss = true});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: UserService().getCurrentUserModel(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!;

        // Don't show if user is already an artist
        if (user.userType == 'artist' || user.userType == 'gallery') {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ArtbeatColors.primary.withValues(alpha: 0.1),
                ArtbeatColors.accentOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ArtbeatColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _navigateToSubscription(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with optional dismiss button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            color: ArtbeatColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Are you an artist?',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: ArtbeatColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Turn your passion into profit',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: ArtbeatColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (showDismiss)
                          IconButton(
                            onPressed: () {
                              // TODO: Implement dismiss functionality
                            },
                            icon: const Icon(
                              Icons.close,
                              color: ArtbeatColors.textSecondary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Features row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeature(
                          icon: Icons.storefront_outlined,
                          text: 'Sell art',
                        ),
                        _buildFeature(
                          icon: Icons.analytics_outlined,
                          text: 'Track sales',
                        ),
                        _buildFeature(
                          icon: Icons.groups_outlined,
                          text: 'Build audience',
                        ),
                        _buildFeature(
                          icon: Icons.trending_up_outlined,
                          text: 'Grow income',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            onTap ?? () => _navigateToSubscription(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Get Started - From \$4.99/month',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Join thousands of artists already earning on ARTbeat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeature({required IconData icon, required String text}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ArtbeatColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: ArtbeatColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription/plans');
  }
}

/// Compact version of the artist CTA for smaller spaces
class CompactArtistCTAWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactArtistCTAWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: UserService().getCurrentUserModel(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!;

        // Don't show if user is already an artist
        if (user.userType == 'artist' || user.userType == 'gallery') {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ArtbeatColors.primary.withValues(alpha: 0.1),
                ArtbeatColors.accentOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArtbeatColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _navigateToSubscription(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      color: ArtbeatColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you an artist?',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ArtbeatColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Start selling your art today',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ArtbeatColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Start',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription/plans');
  }
}
