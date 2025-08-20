import 'package:flutter/material.dart';
import '../models/ad_type.dart';
import 'base_ad_create_screen.dart';

/// Gallery ad creation screen - redirects to unified architecture
class GalleryAdCreateScreen extends StatelessWidget {
  const GalleryAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.rectangle,
      userType: 'gallery',
      screenTitle: 'Create Gallery Ad',
    );
  }
}
