import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';

/// Event card widget using the universal engagement system
/// This replaces the old event card with Appreciate/Connect/Discuss/Amplify actions
class EventCard extends StatelessWidget {
  final ArtbeatEvent event;
  final VoidCallback? onTap;
  final bool showTicketInfo;
  final bool showArtistInfo;
  final bool compact;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showTicketInfo = false,
    this.showArtistInfo = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy • h:mm a');
    final eventDate = event.dateTime;

    return UniversalContentCard(
      contentId: event.id,
      contentType: 'event',
      title: event.title,
      subtitle: dateFormatter.format(eventDate),
      description: event.description,
      imageUrl: event.imageUrls.isNotEmpty
          ? event.imageUrls.first
          : event.eventBannerUrl,
      authorName: '', // Will need to be fetched from artist profile
      authorImageUrl: event.artistHeadshotUrl,
      authorId: event.artistId,
      createdAt: event.createdAt,
      engagementStats: EngagementStats(
        lastUpdated: DateTime.now(),
      ), // Default empty stats
      tags: event.tags,
      onTap: onTap,
      onAuthorTap: () {
        // Navigate to organizer profile
        // This would be handled by the parent widget
      },
      isCompact: compact,
      customContent: showTicketInfo ? _buildTicketInfo() : null,
    );
  }

  Widget _buildTicketInfo() {
    final hasTickets = event.ticketTypes.isNotEmpty;
    final lowestPrice = hasTickets
        ? event.ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final availableTickets =
        event.totalAvailableTickets - event.totalTicketsSold;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number,
            color: ArtbeatColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.hasFreeTickets && !event.hasPaidTickets
                  ? 'Free Event'
                  : event.hasPaidTickets
                  ? 'Tickets from \$${lowestPrice.toStringAsFixed(2)}'
                  : 'No tickets available',
              style: const TextStyle(
                color: ArtbeatColors.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (availableTickets > 0)
            Text(
              '$availableTickets left',
              style: const TextStyle(
                color: ArtbeatColors.darkGray,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
