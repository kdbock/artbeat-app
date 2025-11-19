import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/group_models.dart';
import '../screens/feed/create_group_post_screen.dart';

/// Floating Action Button for creating posts in different groups
class CreatePostFAB extends StatelessWidget {
  final GroupType groupType;
  final VoidCallback? onPostCreated;

  const CreatePostFAB({super.key, required this.groupType, this.onPostCreated});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreatePostOptions(context),
      backgroundColor: _getGroupColor(),
      foregroundColor: Colors.white,
      icon: Icon(_getGroupIcon()),
      label: Text(_getCreateLabel()),
    );
  }

  void _showCreatePostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getGroupColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getGroupIcon(),
                        color: _getGroupColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create ${groupType.title} Post',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            _getCreateDescription(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Create options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _buildCreateOptions(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCreateOptions(BuildContext context) {
    switch (groupType) {
      case GroupType.artist:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.photo_camera,
            title: 'Share Artwork',
            subtitle: 'Post photos of your latest creation',
            color: ArtbeatColors.primaryPurple,
            postType: 'artwork',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.video_camera_back,
            title: 'Process Video',
            subtitle: 'Share your creative process',
            color: ArtbeatColors.primaryGreen,
            postType: 'process',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.text_fields,
            title: 'Artist Update',
            subtitle: 'Share thoughts or updates',
            color: ArtbeatColors.secondaryTeal,
            postType: 'update',
          ),
        ];

      case GroupType.event:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.event_seat,
            title: 'Hosting Event',
            subtitle: 'Share an event you\'re organizing',
            color: ArtbeatColors.primaryGreen,
            postType: 'hosting',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.event_available,
            title: 'Attending Event',
            subtitle: 'Share an event you\'re attending',
            color: ArtbeatColors.secondaryTeal,
            postType: 'attending',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.photo_camera,
            title: 'Event Photos',
            subtitle: 'Share photos from an event',
            color: ArtbeatColors.accentYellow,
            postType: 'photos',
          ),
        ];

      case GroupType.artWalk:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.add_a_photo,
            title: 'Share Art Walk',
            subtitle: 'Post up to 5 photos from your route',
            color: ArtbeatColors.secondaryTeal,
            postType: 'artwalk',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.map,
            title: 'Create Route',
            subtitle: 'Design a new art walking route',
            color: ArtbeatColors.primaryPurple,
            postType: 'route',
          ),
        ];

      case GroupType.artistWanted:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.work_outline,
            title: 'Post Project',
            subtitle: 'Looking for an artist for your project',
            color: ArtbeatColors.accentYellow,
            postType: 'project',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.person_add,
            title: 'Offer Services',
            subtitle: 'Share your availability and skills',
            color: ArtbeatColors.primaryGreen,
            postType: 'services',
          ),
        ];
    }
  }

  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String postType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => CreateGroupPostScreen(
                  groupType: groupType,
                  postType: postType,
                ),
              ),
            ).then((result) {
              if (result == true) {
                onPostCreated?.call();
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGroupColor() {
    switch (groupType) {
      case GroupType.artist:
        return ArtbeatColors.primaryPurple;
      case GroupType.event:
        return ArtbeatColors.primaryGreen;
      case GroupType.artWalk:
        return ArtbeatColors.secondaryTeal;
      case GroupType.artistWanted:
        return ArtbeatColors.accentYellow;
    }
  }

  IconData _getGroupIcon() {
    switch (groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  String _getCreateLabel() {
    switch (groupType) {
      case GroupType.artist:
        return 'Share Art';
      case GroupType.event:
        return 'Add Event';
      case GroupType.artWalk:
        return 'Share Walk';
      case GroupType.artistWanted:
        return 'Post Job';
    }
  }

  String _getCreateDescription() {
    switch (groupType) {
      case GroupType.artist:
        return 'Share your artwork with the community';
      case GroupType.event:
        return 'Share art events and exhibitions';
      case GroupType.artWalk:
        return 'Share your art discovery adventures';
      case GroupType.artistWanted:
        return 'Find artists or offer your services';
    }
  }
}
