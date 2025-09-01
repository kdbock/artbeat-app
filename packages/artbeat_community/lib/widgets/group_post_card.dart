import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/group_models.dart';

/// Card widget for displaying group posts with appropriate actions
class GroupPostCard extends StatelessWidget {
  final BaseGroupPost post;
  final GroupType groupType;
  final VoidCallback onAppreciate;
  final VoidCallback onComment;
  final VoidCallback onFeature;
  final VoidCallback onGift;
  final VoidCallback onShare;
  final bool isCompact;

  const GroupPostCard({
    super.key,
    required this.post,
    required this.groupType,
    required this.onAppreciate,
    required this.onComment,
    required this.onFeature,
    required this.onGift,
    required this.onShare,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the existing content inside UniversalContentCard using customContent
    return UniversalContentCard(
      contentId: post.id,
      contentType: _getContentType(),
      title: post.content.isNotEmpty
          ? (post.content.length > 80
                ? '${post.content.substring(0, 77)}...'
                : post.content)
          : '',
      description: post.content.isNotEmpty ? post.content : null,
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
      authorName: post.userName,
      authorImageUrl: post.userPhotoUrl,
      authorId: post.userId,
      createdAt: post.createdAt,
      engagementStats: EngagementStats(
        appreciateCount: post.applauseCount,
        discussCount: post.commentCount,
        amplifyCount: post.shareCount,
        lastUpdated: DateTime.now(),
      ),
      tags: post.tags,
      isCompact: isCompact,
      showGift: true,
      showConnect: false,
      onDiscuss: onComment,
      onGift: onGift,
      onAmplify: onShare,
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContent(),
          if (post.imageUrls.isNotEmpty) _buildImages(),
          _buildSpecializedContent(),
          _buildHashtags(),
        ],
      ),
    );
  }

  String _getContentType() {
    // Map group types to a generic 'post' contentType for universal card
    return 'post';
  }

  // Group badge and legacy action helpers removed - UI now uses UniversalContentCard

  Widget _buildContent() {
    if (post.content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.content,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildImages() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: post.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: EdgeInsets.only(
              right: index < post.imageUrls.length - 1 ? 8 : 0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image:
                  post.imageUrls[index].isNotEmpty &&
                      Uri.tryParse(post.imageUrls[index])?.hasScheme == true
                  ? DecorationImage(
                      image:
                          NetworkImage(post.imageUrls[index]) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
              color:
                  post.imageUrls[index].isEmpty ||
                      Uri.tryParse(post.imageUrls[index])?.hasScheme != true
                  ? Colors.grey[300]
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecializedContent() {
    switch (groupType) {
      case GroupType.artist:
        return _buildArtistContent(post as ArtistGroupPost);
      case GroupType.event:
        return _buildEventContent(post as EventGroupPost);
      case GroupType.artWalk:
        return _buildArtWalkContent(post as ArtWalkAdventurePost);
      case GroupType.artistWanted:
        return _buildArtistWantedContent(post as ArtistWantedPost);
    }
  }

  Widget _buildArtistContent(ArtistGroupPost artistPost) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artistPost.artworkTitle.isNotEmpty) ...[
            Text(
              artistPost.artworkTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          if (artistPost.artworkDescription.isNotEmpty) ...[
            Text(
              artistPost.artworkDescription,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (artistPost.medium.isNotEmpty) ...[
                _buildInfoChip(Icons.brush, artistPost.medium),
                const SizedBox(width: 8),
              ],
              if (artistPost.style.isNotEmpty) ...[
                _buildInfoChip(Icons.style, artistPost.style),
                const SizedBox(width: 8),
              ],
              if (artistPost.isForSale && artistPost.price != null) ...[
                _buildInfoChip(
                  Icons.attach_money,
                  '\$${artistPost.price!.toStringAsFixed(0)}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(EventGroupPost eventPost) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventPost.eventTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            eventPost.eventDescription,
            style: const TextStyle(
              fontSize: 14,
              color: ArtbeatColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                DateFormat('MMM d, y').format(eventPost.eventDate),
              ),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.location_on, eventPost.eventLocation),
              const SizedBox(width: 8),
              _buildInfoChip(
                eventPost.eventType == 'hosting'
                    ? Icons.event_seat
                    : Icons.event_available,
                eventPost.eventType.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtWalkContent(ArtWalkAdventurePost walkPost) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            walkPost.routeName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.straighten,
                '${walkPost.walkDistance.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.access_time,
                '${walkPost.estimatedDuration} min',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.trending_up,
                walkPost.difficulty.toUpperCase(),
              ),
            ],
          ),
          if (walkPost.artworkPhotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${walkPost.artworkPhotos.length} artwork photos',
              style: const TextStyle(
                fontSize: 12,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistWantedContent(ArtistWantedPost wantedPost) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  wantedPost.projectTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (wantedPost.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wantedPost.projectDescription,
            style: const TextStyle(
              fontSize: 14,
              color: ArtbeatColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.attach_money,
                '\$${wantedPost.budget.toStringAsFixed(0)} ${wantedPost.budgetType}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.schedule,
                DateFormat('MMM d').format(wantedPost.deadline),
              ),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.star, wantedPost.experienceLevel),
            ],
          ),
          if (wantedPost.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: wantedPost.requiredSkills
                  .take(3)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 10,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ArtbeatColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ArtbeatColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: ArtbeatColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtags() {
    if (post.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: post.tags
            .map(
              (tag) => Text(
                '#$tag',
                style: const TextStyle(
                  color: ArtbeatColors.primaryPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Legacy action row removed; engagement handled by UniversalEngagementBar

  Widget _buildActionButton({
    required String label,
    required int count,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionIcon(label, color),
              const SizedBox(height: 2),
              if (count > 0)
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(String label, Color color) {
    IconData iconData;
    switch (label.toLowerCase()) {
      case 'appreciate':
        iconData = Icons.favorite_border;
        break;
      case 'comment':
        iconData = Icons.chat_bubble_outline;
        break;
      case 'feature':
        iconData = Icons.star_border;
        break;
      case 'gift':
        iconData = Icons.card_giftcard;
        break;
      case 'share':
        iconData = Icons.share;
        break;
      default:
        iconData = Icons.help_outline;
    }

    return Icon(iconData, size: 18, color: color);
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

  String _getGroupLabel() {
    switch (groupType) {
      case GroupType.artist:
        return 'ARTIST';
      case GroupType.event:
        return 'EVENT';
      case GroupType.artWalk:
        return 'ART WALK';
      case GroupType.artistWanted:
        return 'WANTED';
    }
  }

  // Removed legacy helpers - group visuals handled by UniversalContentCard/customContent
}
