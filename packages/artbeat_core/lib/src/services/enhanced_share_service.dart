import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

/// Enhanced sharing service with URL-based social media integration
class EnhancedShareService {
  static final EnhancedShareService _instance =
      EnhancedShareService._internal();
  factory EnhancedShareService() => _instance;
  EnhancedShareService._internal();

  static const String _baseAppUrl = 'https://artbeat.app';
  static const String _fallbackAppUrl = 'https://artbeat.page.link';

  /// Share artwork on Facebook
  Future<bool> shareOnFacebook({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
    String? imageUrl,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';
      final facebookUrl =
          'https://www.facebook.com/dialog/share'
          '?app_id=YOUR_FACEBOOK_APP_ID'
          '&display=popup'
          '&href=$deepLink'
          '&redirect_uri=$_fallbackAppUrl';

      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
        await launchUrl(
          Uri.parse(facebookUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared artwork on Facebook: $artworkId');
        return true;
      } else {
        AppLogger.warning('⚠️ Cannot launch Facebook share');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error sharing on Facebook: $e');
      return false;
    }
  }

  /// Share artwork on Instagram
  Future<bool> shareOnInstagram({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';
      final instagramUrl = 'instagram://share?url=$deepLink';

      if (await canLaunchUrl(Uri.parse(instagramUrl))) {
        await launchUrl(
          Uri.parse(instagramUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared artwork on Instagram: $artworkId');
        return true;
      } else {
        // Fallback to Instagram web
        final webUrl = 'https://www.instagram.com/?url=$deepLink';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(
            Uri.parse(webUrl),
            mode: LaunchMode.externalApplication,
          );
          return true;
        }
        AppLogger.warning('⚠️ Cannot launch Instagram share');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error sharing on Instagram: $e');
      return false;
    }
  }

  /// Share artwork via Stories (Instagram/Facebook)
  Future<bool> shareToStories({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
    String? backgroundImage,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';

      // Try Instagram Stories first
      final instagramStoriesUrl = 'instagram://stories/share?url=$deepLink';
      if (await canLaunchUrl(Uri.parse(instagramStoriesUrl))) {
        await launchUrl(
          Uri.parse(instagramStoriesUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared to Instagram Stories: $artworkId');
        return true;
      }

      // Fallback to Facebook Stories
      final facebookStoriesUrl =
          'https://www.facebook.com/stories/create'
          '?url=$deepLink';
      if (await canLaunchUrl(Uri.parse(facebookStoriesUrl))) {
        await launchUrl(
          Uri.parse(facebookStoriesUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared to Facebook Stories: $artworkId');
        return true;
      }

      AppLogger.warning('⚠️ Cannot launch Stories share');
      return false;
    } catch (e) {
      AppLogger.error('❌ Error sharing to Stories: $e');
      return false;
    }
  }

  /// Share artwork via Twitter/X
  Future<bool> shareOnTwitter({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';
      final tweetText = Uri.encodeComponent(
        '✨ Check out "$artworkTitle" by $artistName on ArtBeat! 🎨\n\n$deepLink',
      );

      final twitterUrl =
          'https://twitter.com/intent/tweet?text=$tweetText&url=$deepLink';

      if (await canLaunchUrl(Uri.parse(twitterUrl))) {
        await launchUrl(
          Uri.parse(twitterUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared artwork on Twitter: $artworkId');
        return true;
      } else {
        AppLogger.warning('⚠️ Cannot launch Twitter share');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error sharing on Twitter: $e');
      return false;
    }
  }

  /// Share artwork via WhatsApp
  Future<bool> shareOnWhatsApp({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';
      final message = Uri.encodeComponent(
        '🎨 $artworkTitle by $artistName\n\nCheck it out on ArtBeat:\n$deepLink',
      );

      final whatsappUrl = 'whatsapp://send?text=$message';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('✅ Shared artwork on WhatsApp: $artworkId');
        return true;
      } else {
        AppLogger.warning('⚠️ Cannot launch WhatsApp share');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error sharing on WhatsApp: $e');
      return false;
    }
  }

  /// Share artwork via Email
  Future<bool> shareViaEmail({
    required String artworkId,
    required String artworkTitle,
    required String artistName,
    String? userEmail,
  }) async {
    try {
      final deepLink = '$_baseAppUrl/artwork/$artworkId';
      final subject = Uri.encodeComponent(
        'Check out "$artworkTitle" on ArtBeat',
      );
      final body = Uri.encodeComponent(
        'I found this amazing artwork on ArtBeat!\n\n'
        'Title: $artworkTitle\n'
        'Artist: $artistName\n\n'
        'View it here: $deepLink',
      );

      final emailUrl = 'mailto:${userEmail ?? ''}?subject=$subject&body=$body';

      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        AppLogger.info('✅ Shared artwork via Email: $artworkId');
        return true;
      } else {
        AppLogger.warning('⚠️ Cannot launch Email share');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error sharing via Email: $e');
      return false;
    }
  }

  /// Generate deep link for artwork
  String generateDeepLink(String artworkId) {
    return '$_baseAppUrl/artwork/$artworkId';
  }

  /// Generate share message
  String generateShareMessage({
    required String artworkTitle,
    required String artistName,
  }) {
    return '✨ Check out "$artworkTitle" by $artistName on ArtBeat! 🎨';
  }

  /// Get all available share platforms
  List<Map<String, dynamic>> getAvailablePlatforms() {
    return [
      {
        'platform': 'facebook',
        'icon': 'assets/icons/facebook.svg',
        'label': 'Facebook',
        'color': 0xFF1877F2,
      },
      {
        'platform': 'instagram',
        'icon': 'assets/icons/instagram.svg',
        'label': 'Instagram',
        'color': 0xFFE4405F,
      },
      {
        'platform': 'twitter',
        'icon': 'assets/icons/twitter.svg',
        'label': 'Twitter/X',
        'color': 0xFF000000,
      },
      {
        'platform': 'whatsapp',
        'icon': 'assets/icons/whatsapp.svg',
        'label': 'WhatsApp',
        'color': 0xFF25D366,
      },
      {
        'platform': 'email',
        'icon': 'assets/icons/email.svg',
        'label': 'Email',
        'color': 0xFFEA4335,
      },
      {
        'platform': 'stories',
        'icon': 'assets/icons/stories.svg',
        'label': 'Stories',
        'color': 0xFF833AB4,
      },
    ];
  }
}
