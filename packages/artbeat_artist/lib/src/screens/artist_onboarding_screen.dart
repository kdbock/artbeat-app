import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/artist_profile_service.dart';

class ArtistOnboardingScreen extends StatefulWidget {
  final core.UserModel user;
  final VoidCallback? onComplete;

  const ArtistOnboardingScreen({
    super.key,
    required this.user,
    this.onComplete,
  });

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  final List<String> _selectedMediums = [];
  final List<String> _selectedStyles = [];
  bool _isSubmitting = false;

  // Available options for art mediums and styles
  final List<String> _availableMediums = [
    'Oil',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Photography',
    'Sculpture',
    'Mixed Media',
    'Other'
  ];

  final List<String> _availableStyles = [
    'Abstract',
    'Realism',
    'Impressionism',
    'Pop Art',
    'Minimalism',
    'Contemporary',
    'Traditional',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Create artist profile
      final artistProfileService = ArtistProfileService();
      final userService = core.UserService();

      await artistProfileService.createArtistProfile(
        userId: widget.user.id,
        displayName: widget.user.fullName,
        bio: _bioController.text,
        website: _websiteController.text,
        mediums: _selectedMediums,
        styles: _selectedStyles,
        userType: core.UserType.artist,
        subscriptionTier: core.SubscriptionTier.artistBasic,
      );

      // Update user type in core user model
      await userService.updateUserProfileWithMap({
        'userType': core.UserType.artist.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artist profile created successfully!')),
        );
        // Navigate to subscription comparison after onboarding
        Navigator.pushNamed(context, '/subscription/comparison');
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating artist profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const core.UniversalHeader(
          title: 'Become an Artist',
          showLogo: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to ARTbeat for Artists',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your artist profile to get started.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Artist Bio',
                    hintText: 'Tell us about your artistic journey...',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    hintText: 'https://your-portfolio.com',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Art Mediums',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableMediums.map((medium) {
                    return FilterChip(
                      label: Text(medium),
                      selected: _selectedMediums.contains(medium),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMediums.add(medium);
                          } else {
                            _selectedMediums.remove(medium);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedMediums.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select at least one medium',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Art Styles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableStyles.map((style) {
                    return FilterChip(
                      label: Text(style),
                      selected: _selectedStyles.contains(style),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStyles.add(style);
                          } else {
                            _selectedStyles.remove(style);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedStyles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select at least one style',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ||
                            _selectedMediums.isEmpty ||
                            _selectedStyles.isEmpty
                        ? null
                        : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Artist Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
