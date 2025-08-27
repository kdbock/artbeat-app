import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';

/// Minimal subscription plans screen for testing navigation
class SimpleSubscriptionPlansScreen extends StatelessWidget {
  const SimpleSubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: ArtbeatColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette, size: 64, color: ArtbeatColors.primary),
              SizedBox(height: 16),
              Text(
                'Subscription Plans',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Navigation is working!',
                style: TextStyle(
                  fontSize: 16,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Choose a plan to get started as an artist.',
                style: TextStyle(
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
