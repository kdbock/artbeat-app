import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/title_sponsorship_model.dart';
import '../services/title_sponsorship_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display title sponsor badge
/// Can be used on splash screen, drawer header, or other locations
class TitleSponsorBadge extends StatelessWidget {
  final TitleSponsorshipService _sponsorshipService = TitleSponsorshipService();
  final String location; // For analytics tracking
  final double size; // Logo size
  final bool showText; // Show "Sponsored by" text
  final bool isClickable; // Allow clicking to visit sponsor website

  TitleSponsorBadge({
    super.key,
    required this.location,
    this.size = 60.0,
    this.showText = true,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TitleSponsorshipModel?>(
      stream: _sponsorshipService.watchActiveSponsor(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final sponsor = snapshot.data!;

        // Track impression
        _sponsorshipService.trackImpression(sponsor.id, location);

        return _buildSponsorBadge(context, sponsor);
      },
    );
  }

  Widget _buildSponsorBadge(
    BuildContext context,
    TitleSponsorshipModel sponsor,
  ) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Sponsored by',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: sponsor.logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: (context, url) => SizedBox(
              width: size,
              height: size,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business,
                size: size * 0.5,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );

    if (isClickable && sponsor.websiteUrl != null) {
      return InkWell(
        onTap: () => _launchSponsorWebsite(sponsor.websiteUrl!),
        child: content,
      );
    }

    return content;
  }

  Future<void> _launchSponsorWebsite(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error('Error launching sponsor website: $e');
    }
  }
}

/// Compact horizontal sponsor badge for drawer header
class CompactSponsorBadge extends StatelessWidget {
  final TitleSponsorshipService _sponsorshipService = TitleSponsorshipService();

  CompactSponsorBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TitleSponsorshipModel?>(
      stream: _sponsorshipService.watchActiveSponsor(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final sponsor = snapshot.data!;

        // Track impression
        _sponsorshipService.trackImpression(sponsor.id, 'drawer_header');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sponsored by',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: sponsor.logoUrl,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.business, size: 16, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Loading screen sponsor badge (minimal, non-intrusive)
class LoadingSponsorBadge extends StatelessWidget {
  final TitleSponsorshipService _sponsorshipService = TitleSponsorshipService();

  LoadingSponsorBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TitleSponsorshipModel?>(
      stream: _sponsorshipService.watchActiveSponsor(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final sponsor = snapshot.data!;

        // Track impression
        _sponsorshipService.trackImpression(sponsor.id, 'loading_screen');

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Powered by',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              const SizedBox(width: 6),
              CachedNetworkImage(
                imageUrl: sponsor.logoUrl,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
