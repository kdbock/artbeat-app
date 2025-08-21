import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../controllers/ad_form_controller.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../widgets/universal_ad_form.dart';
import '../widgets/ads_header.dart';
import '../widgets/ads_drawer.dart';
import '../services/ad_business_service.dart';

/// Base screen for all ad creation flows
/// Provides common scaffold and handles form submission
class BaseAdCreateScreen extends StatefulWidget {
  final AdType initialAdType;
  final String userType;
  final String screenTitle;

  const BaseAdCreateScreen({
    super.key,
    required this.initialAdType,
    required this.userType,
    required this.screenTitle,
  });

  @override
  State<BaseAdCreateScreen> createState() => _BaseAdCreateScreenState();
}

class _BaseAdCreateScreenState extends State<BaseAdCreateScreen> {
  late AdFormController _controller;
  final AdBusinessService _businessService = AdBusinessService();
  List<AdLocation> _availableLocations = [];

  @override
  void initState() {
    super.initState();
    _controller = AdFormController();
    _controller.initializeForAdType(widget.initialAdType);
    _loadAvailableLocations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadAvailableLocations() {
    _availableLocations = _businessService.getAvailableLocations(
      widget.userType,
    );
    if (_availableLocations.isNotEmpty) {
      _controller.setAdLocation(_availableLocations.first);
    }
  }

  Future<void> _handleSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please log in to create an ad');
      return;
    }

    final success = await _controller.submitAd(
      userId: user.uid,
      userType: widget.userType,
    );

    if (success && mounted) {
      _showSuccess();
      Navigator.of(context).pop();
    }
  }

  void _showSuccess() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ad submitted successfully!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Status',
          textColor: Colors.white,
          onPressed: () {
            // Check mounted state before navigation
            if (mounted) {
              Navigator.of(context).pushNamed('/ads/status');
            }
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdFormController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AdsHeader(title: widget.screenTitle, showBackButton: true),
        drawer: const AdsDrawer(),
        body: SafeArea(
          child: UniversalAdForm(
            initialAdType: widget.initialAdType,
            userType: widget.userType,
            availableLocations: _availableLocations,
            onSubmit: _handleSubmit,
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

/// Specific implementation for Artist Ad Creation
class ArtistAdCreateScreen extends StatelessWidget {
  const ArtistAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'artist',
      screenTitle: '🎨 Artist Ad Studio',
    );
  }
}

/// Specific implementation for Gallery Ad Creation
class GalleryAdCreateScreen extends StatelessWidget {
  const GalleryAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'gallery',
      screenTitle: '🏛️ Gallery Promotions',
    );
  }
}

/// Specific implementation for User Ad Creation
class UserAdCreateScreen extends StatelessWidget {
  const UserAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'user',
      screenTitle: '📢 Create Your Ad',
    );
  }
}

/// Specific implementation for Admin Ad Creation
class AdminAdCreateScreen extends StatelessWidget {
  const AdminAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'admin',
      screenTitle: '⚡ Admin Ad Manager',
    );
  }
}
