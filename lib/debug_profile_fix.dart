import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

/// Temporary debug screen to fix profile image URL
class DebugProfileFix extends StatefulWidget {
  const DebugProfileFix({super.key});

  @override
  State<DebugProfileFix> createState() => _DebugProfileFixState();
}

class _DebugProfileFixState extends State<DebugProfileFix> {
  final UserService _userService = UserService();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _currentProfileUrl;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUserModel();
      setState(() {
        _currentUser = user;
        _currentProfileUrl = user?.profileImageUrl;
        _urlController.text = _currentProfileUrl ?? '';
      });
    } on Exception catch (e) {
      AppLogger.error('Error loading user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImageUrl() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a URL')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userService.updateUserProfileWithMap({
        'profileImageUrl': _urlController.text.trim(),
        'photoUrl': _urlController.text.trim(), // Update both fields
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image URL updated successfully!'),
        ),
      );

      // Reload user data
      await _loadCurrentUser();
    } on Exception catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Debug Profile Fix'),
      backgroundColor: ArtbeatColors.primaryPurple,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current User Info:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (_currentUser != null) ...[
            Text('Name: ${_currentUser!.fullName}'),
            Text('Email: ${_currentUser!.email}'),
            Text('Current Profile URL: ${_currentProfileUrl ?? "None"}'),
          ],
          const SizedBox(height: 24),

          Text(
            'Your Firebase Storage URL:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const SelectableText(
            'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/profile_images%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2Fprofile.jpg?alt=media&token=2b5eafc4-0b82-441c-8bf5-d60a38b51586',
            style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),

          Text(
            'Update Profile Image URL:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Profile Image URL',
              hintText: 'Enter the full Firebase Storage URL',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfileImageUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Profile Image URL'),
            ),
          ),

          const SizedBox(height: 24),
          if (_currentProfileUrl != null && _currentProfileUrl!.isNotEmpty) ...[
            Text(
              'Current Avatar Preview:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(
              child: OptimizedAvatar(
                imageUrl: _currentProfileUrl,
                displayName: _currentUser?.fullName ?? 'User',
                radius: 50,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
