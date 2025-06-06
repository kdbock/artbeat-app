import 'package:flutter/material.dart';
import '../../theme/artbeat_colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ArtbeatColors.primaryGradient,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ArtbeatColors.white),
          ),
        ),
      ),
    );
  }
}
