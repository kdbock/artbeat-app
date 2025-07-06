import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';

/// Card widget for displaying event information in lists
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventBanner(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventTitle(),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    _buildEventDescription(),
                  ],
                  const SizedBox(height: 12),
                  _buildEventInfo(),
                  if (showArtistInfo && !compact) ...[
                    const SizedBox(height: 12),
                    _buildArtistInfo(),
                  ],
                  if (showTicketInfo) ...[
                    const SizedBox(height: 12),
                    _buildTicketInfo(),
                  ],
                  const SizedBox(height: 8),
                  _buildEventTags(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return SizedBox(
      height: compact ? 120 : 200,
      width: double.infinity,
      child: event.eventBannerUrl.isNotEmpty
          ? ImageManagementService().getOptimizedImage(
              imageUrl: event.eventBannerUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: compact ? 120 : 200,
              isThumbnail: compact,
              errorWidget: _buildPlaceholderBanner(),
            )
          : _buildPlaceholderBanner(),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: compact ? 32 : 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Event Banner',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTitle() {
    return Text(
      event.title,
      style: TextStyle(
        fontSize: compact ? 16 : 20,
        fontWeight: FontWeight.bold,
      ),
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventDescription() {
    return Text(
      event.description,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
      maxLines: compact ? 1 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventInfo() {
    return Column(
      children: [
        // Date and time
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, y').format(event.dateTime),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              DateFormat('h:mm a').format(event.dateTime),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Location
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.location,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArtistInfo() {
    return Row(
      children: [
        // Artist headshot
        CircleAvatar(
          radius: 16,
          backgroundImage: event.artistHeadshotUrl.isNotEmpty
              ? NetworkImage(event.artistHeadshotUrl)
              : null,
          child: event.artistHeadshotUrl.isEmpty
              ? const Icon(Icons.person, size: 16)
              : null,
        ),
        const SizedBox(width: 8),
        FutureBuilder<String?>(
          future: _fetchArtistName(event.artistId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 60,
                height: 12,
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final artistName = snapshot.data ?? 'Artist';
            return Text(
              'By $artistName',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<String?> _fetchArtistName(String artistId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .doc(artistId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['displayName'] != null) {
          return data['displayName'] as String;
        }
      }
    } on Exception catch (e) {
      // Log the error but return null as fallback
      debugPrint('Error fetching artist name: $e');
    }
    return null;
  }

  Widget _buildTicketInfo() {
    if (event.ticketTypes.isEmpty) return const SizedBox.shrink();

    // Determine ticket price range
    final prices = event.ticketTypes
        .where((ticket) => ticket.isAvailable)
        .map((ticket) => ticket.price)
        .toList();

    if (prices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Sold Out',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    String priceText;
    Color priceColor;

    if (minPrice == 0 && maxPrice == 0) {
      priceText = 'Free';
      priceColor = Colors.green.shade700;
    } else if (minPrice == 0) {
      priceText = 'Free - \$${maxPrice.toStringAsFixed(2)}';
      priceColor = Colors.blue.shade700;
    } else if (minPrice == maxPrice) {
      priceText = '\$${minPrice.toStringAsFixed(2)}';
      priceColor = Colors.blue.shade700;
    } else {
      priceText =
          '\$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}';
      priceColor = Colors.blue.shade700;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: priceColor == Colors.green.shade700
                ? Colors.green.shade50
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: priceColor == Colors.green.shade700
                  ? Colors.green.shade200
                  : Colors.blue.shade200,
            ),
          ),
          child: Text(
            priceText,
            style: TextStyle(
              color: priceColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Availability indicator
        if (event.isSoldOut)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sold Out',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (event.totalTicketsSold > event.totalAvailableTickets * 0.8)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Few Left',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTags() {
    if (event.tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: event.tags.take(compact ? 2 : 4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }
}
