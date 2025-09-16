import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Container widget that loads an artist profile by ID (or current user if no ID provided)
/// and displays their community feed
class ArtistFeedContainerWithParams extends StatefulWidget { // If null, shows current user's feed

  const ArtistFeedContainerWithParams({super.key, this.artistUserId});
  final String? artistUserId;

  @override
  State<ArtistFeedContainerWithParams> createState() =>
      _ArtistFeedContainerWithParamsState();
}

class _ArtistFeedContainerWithParamsState
    extends State<ArtistFeedContainerWithParams> {
  ArtistProfileModel? _artistProfile;
  bool _isLoading = true;
  String? _errorMessage;
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    try {
      String? targetUserId = widget.artistUserId;

      // If no artist ID provided, use current user
      if (targetUserId == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _errorMessage = 'You must be logged in to view your artist feed';
            _isLoading = false;
          });
          return;
        }
        targetUserId = user.uid;
      }

      final profile = await _subscriptionService.getArtistProfileByUserId(
        targetUserId,
      );

      if (profile == null) {
        final isCurrentUser =
            targetUserId == FirebaseAuth.instance.currentUser?.uid;
        setState(() {
          _errorMessage = isCurrentUser
              ? 'You must have an artist profile to view your artist feed. Please create one first.'
              : 'This artist profile could not be found.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _artistProfile = profile as ArtistProfileModel?;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading artist profile: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading artist feed...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      final isCurrentUser =
          widget.artistUserId == null ||
          widget.artistUserId == FirebaseAuth.instance.currentUser?.uid;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (isCurrentUser)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/artist/profile-edit');
                },
                child: const Text('Create Artist Profile'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_artistProfile == null) {
      return const Center(child: Text('Artist profile not found'));
    }

    // Show the artist community feed with the loaded profile
    return ArtistCommunityFeedScreen(artist: _artistProfile!);
  }
}
