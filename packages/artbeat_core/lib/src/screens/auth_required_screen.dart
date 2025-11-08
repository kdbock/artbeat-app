import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/enhanced_universal_header.dart';

/// Widget to show when authentication is required
class AuthRequiredScreen extends StatelessWidget {
  const AuthRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'auth_required_title'.tr(),
        showLogo: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'auth_required_title'.tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'auth_required_message'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/auth');
              },
              child: Text('auth_required_button'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
