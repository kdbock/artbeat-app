import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';

/// Minimal subscription plans screen for testing navigation
class SimpleSubscriptionPlansScreen extends StatelessWidget {
  const SimpleSubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_plans_title'.tr()),
        backgroundColor: ArtbeatColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.palette, size: 64, color: ArtbeatColors.primary),
              const SizedBox(height: 16),
              Text(
                'subscription_plans_title'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'subscription_plans_nav_working'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'subscription_plans_cta'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
