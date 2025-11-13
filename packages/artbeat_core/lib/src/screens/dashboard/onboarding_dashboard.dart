import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/artbeat_colors.dart';
import '../../theme/artbeat_typography.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/artbeat_drawer.dart';
import '../../services/user_service.dart';
import '../../utils/logger.dart';
import '../artbeat_dashboard_screen.dart';

/// Onboarding Dashboard - Guided First-Time User Experience
///
/// Designed for new users who need to:
/// - Complete their profile setup
/// - Learn about app features
/// - Connect with the community
/// - Start their first art walk or capture
class OnboardingDashboard extends StatefulWidget {
  const OnboardingDashboard({super.key, required this.user});

  final UserModel user;

  @override
  State<OnboardingDashboard> createState() => _OnboardingDashboardState();
}

class _OnboardingDashboardState extends State<OnboardingDashboard> {
  final ScrollController _scrollController = ScrollController();
  int _currentStep = 0;

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      title: 'onboarding_welcome_title',
      description: 'onboarding_welcome_description',
      icon: Icons.waving_hand,
      color: ArtbeatColors.primaryPurple,
    ),
    const OnboardingStep(
      title: 'onboarding_profile_title',
      description: 'onboarding_profile_description',
      icon: Icons.person,
      color: ArtbeatColors.primaryBlue,
    ),
    const OnboardingStep(
      title: 'onboarding_explore_title',
      description: 'onboarding_explore_description',
      icon: Icons.explore,
      color: ArtbeatColors.primaryGreen,
    ),
    const OnboardingStep(
      title: 'onboarding_create_title',
      description: 'onboarding_create_description',
      icon: Icons.create,
      color: ArtbeatColors.accentOrange,
    ),
    const OnboardingStep(
      title: 'onboarding_connect_title',
      description: 'onboarding_connect_description',
      icon: Icons.people,
      color: ArtbeatColors.accentGold,
    ),
  ];

  late final _formKey = GlobalKey<FormState>();
  late final _fullNameController = TextEditingController();
  late final _usernameController = TextEditingController();
  late final _bioController = TextEditingController();
  late final _locationController = TextEditingController();
  File? _profileImage;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _prefillProfileData();
  }

  void _prefillProfileData() {
    _fullNameController.text = widget.user.fullName;
    _usernameController.text = widget.user.username;
    _bioController.text = widget.user.bio;
    _locationController.text = widget.user.location;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ArtbeatDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: ArtbeatColors.primaryPurple,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Progress
            _buildAppBar(),

            // Welcome Hero Section
            _buildWelcomeHero(),

            // Onboarding Progress
            _buildProgressIndicator(),

            // Current Step Content
            _buildCurrentStep(),

            // Quick Setup Actions
            _buildQuickSetup(),

            // Feature Highlights
            _buildFeatureHighlights(),

            // Community Preview
            _buildCommunityPreview(),

            // Get Started CTA
            _buildGetStarted(),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: const SizedBox.shrink(),
      actions: [
        IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu, color: ArtbeatColors.textPrimary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: widget.user.profileImageUrl.isNotEmpty
                        ? widget.user.profileImageUrl
                        : null,
                    displayName: widget.user.username,
                    radius: 25.0,
                    isVerified: false, // New users not verified yet
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'onboarding_welcome_user'.tr(
                            args: [widget.user.fullName],
                          ),
                          style: ArtbeatTypography.textTheme.headlineSmall!,
                        ),
                        Text(
                          'onboarding_setup_progress'.tr(),
                          style: ArtbeatTypography.textTheme.bodyMedium!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHero() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Image.asset(
                  'assets/images/artbeat_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'onboarding_welcome_to_artbeat'.tr(),
                style: ArtbeatTypography.textTheme.headlineLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'onboarding_discover_create_connect'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding_step_progress'.tr(
                  args: [
                    (_currentStep + 1).toString(),
                    _steps.length.toString(),
                  ],
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'onboarding_your_journey'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_steps.length, (index) {
                final step = _steps[index];
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentStep = index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? step.color
                                : isCurrent
                                ? step.color.withValues(alpha: 0.8)
                                : Colors.grey.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(color: step.color, width: 3)
                                : null,
                          ),
                          child: Icon(
                            step.icon,
                            color: isCompleted || isCurrent
                                ? Colors.white
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.title.tr(),
                          style: ArtbeatTypography.textTheme.bodySmall!
                              .copyWith(
                                color: isCompleted || isCurrent
                                    ? step.color
                                    : Colors.grey,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (index < _steps.length - 1)
                          Flexible(
                            fit: FlexFit.loose,
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: isCompleted
                                  ? step.color
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 1) {
      return _buildProfileForm();
    }

    final step = _steps[_currentStep];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: step.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: step.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title.tr(),
                          style: ArtbeatTypography.textTheme.headlineSmall!
                              .copyWith(
                                color: step.color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description.tr(),
                          style: ArtbeatTypography.textTheme.bodyMedium!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _completeCurrentStep,
                icon: const Icon(Icons.arrow_forward),
                label: Text('onboarding_continue'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: step.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    final step = _steps[1];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: step.color.withValues(alpha: 0.3)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: step.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title.tr(),
                            style: ArtbeatTypography.textTheme.headlineSmall!
                                .copyWith(
                                  color: step.color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _selectProfileImage,
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: step.color, width: 2),
                      ),
                      child: _profileImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.add_a_photo,
                              color: step.color, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Tap to add profile photo',
                    style: ArtbeatTypography.textTheme.bodySmall!,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a unique username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Your city/region',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    icon: _isSavingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_isSavingProfile
                        ? 'Saving...'
                        : 'onboarding_continue'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    try {
      final userService = UserService();

      await userService.updateUserProfile(
        fullName: _fullNameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        zipCode: _locationController.text,
      );

      if (_profileImage != null) {
        await userService.uploadAndUpdateProfilePhoto(_profileImage!);
      }

      _completeCurrentStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Widget _buildQuickSetup() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'onboarding_quick_setup'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSetupCard(
                  icon: Icons.camera_alt,
                  title: 'onboarding_take_first_photo'.tr(),
                  subtitle: 'onboarding_capture_moment'.tr(),
                  color: ArtbeatColors.primaryGreen,
                  onTap: () => _navigateToCamera(context),
                ),
                const SizedBox(width: 12),
                _buildSetupCard(
                  icon: Icons.map,
                  title: 'onboarding_start_art_walk'.tr(),
                  subtitle: 'onboarding_explore_nearby'.tr(),
                  color: ArtbeatColors.primaryBlue,
                  onTap: () => _navigateToArtWalk(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSetupCard(
                  icon: Icons.edit,
                  title: 'onboarding_complete_profile'.tr(),
                  subtitle: 'onboarding_add_bio_photo'.tr(),
                  color: ArtbeatColors.primaryPurple,
                  onTap: () => _navigateToProfileSetup(context),
                ),
                const SizedBox(width: 12),
                _buildSetupCard(
                  icon: Icons.people,
                  title: 'onboarding_find_friends'.tr(),
                  subtitle: 'onboarding_connect_artists'.tr(),
                  color: ArtbeatColors.accentGold,
                  onTap: () => _navigateToCommunity(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: ArtbeatTypography.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: ArtbeatTypography.textTheme.bodyMedium!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'onboarding_discover_features'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureCard(
                    image: 'https://picsum.photos/300/200?random=1',
                    title: 'onboarding_art_walks'.tr(),
                    description: 'onboarding_art_walks_desc'.tr(),
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    image: 'https://picsum.photos/300/200?random=2',
                    title: 'onboarding_captures'.tr(),
                    description: 'onboarding_captures_desc'.tr(),
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    image: 'https://picsum.photos/300/200?random=3',
                    title: 'onboarding_community'.tr(),
                    description: 'onboarding_community_desc'.tr(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String image,
    required String title,
    required String description,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPreview() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ArtbeatColors.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    color: ArtbeatColors.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'onboarding_join_community'.tr(),
                    style: ArtbeatTypography.textTheme.headlineSmall!,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'onboarding_community_description'.tr(),
                style: ArtbeatTypography.textTheme.bodyMedium!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/32/32?random=10',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/32/32?random=11',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/32/32?random=12',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '+1.2K',
                        style: TextStyle(
                          color: ArtbeatColors.primaryPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'onboarding_artists_online'.tr(),
                      style: ArtbeatTypography.textTheme.bodyMedium!.copyWith(
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGetStarted() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ArtbeatColors.primaryGreen, ArtbeatColors.primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'onboarding_ready_to_start'.tr(),
                style: ArtbeatTypography.textTheme.headlineMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'onboarding_begin_journey'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _completeOnboarding,
                icon: const Icon(Icons.rocket_launch),
                label: Text('onboarding_get_started'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ArtbeatColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeCurrentStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final userService = UserService();
    final userId = userService.currentUserId;
    
    try {
      AppLogger.info('🎉 Marking onboarding as complete for user: $userId');
      if (userId == null) {
        AppLogger.warning('❌ Cannot complete onboarding: currentUserId is null');
        return;
      }
      
      await userService.updateUserProfileWithMap({'onboardingCompleted': true});
      
      await Future<void>.delayed(const Duration(milliseconds: 500));
      AppLogger.info('✅ Onboarding marked as complete for $userId');
    } catch (e) {
      AppLogger.warning('❌ Error marking onboarding as complete: $e');
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const ArtbeatDashboardScreen(),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    // Simulate refresh
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // Navigation methods
  void _navigateToCamera(BuildContext context) {
    Navigator.pushNamed(context, '/camera');
  }

  void _navigateToArtWalk(BuildContext context) {
    Navigator.pushNamed(context, '/art-walk');
  }

  void _navigateToProfileSetup(BuildContext context) {
    Navigator.pushNamed(context, '/profile/setup');
  }

  void _navigateToCommunity(BuildContext context) {
    Navigator.pushNamed(context, '/community');
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
