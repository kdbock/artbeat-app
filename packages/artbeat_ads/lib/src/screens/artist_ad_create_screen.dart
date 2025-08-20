import 'package:flutter/material.dart';
import '../models/ad_type.dart';
import 'base_ad_create_screen.dart';

/// Artist ad creation screen - redirects to unified architecture
class ArtistAdCreateScreen extends StatelessWidget {
  const ArtistAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'artist',
      screenTitle: 'Create Artist Ad',
    );
  }
}
