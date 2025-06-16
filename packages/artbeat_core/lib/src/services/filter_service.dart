import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' show ArtworkModel;
import 'package:artbeat_artist/artbeat_artist.dart' show ArtistProfileModel;
import 'package:artbeat_core/artbeat_core.dart';
import '../models/filter_types.dart';
import '../models/user_type.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for handling all filtering operations
class FilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Filter artists based on parameters
  Future<List<ArtistProfileModel>> filterArtists(
      FilterParameters params) async {
    try {
      Query query = _firestore.collection('artistProfiles');

      // Apply base filters
      if (params.artistTypes?.isNotEmpty ?? false) {
        query = query.where('artistType',
            whereIn: params.artistTypes!.map((t) => t.name).toList());
      }

      if (params.artMediums?.isNotEmpty ?? false) {
        query = query.where('mediums',
            arrayContainsAny: params.artMediums!.map((m) => m.name).toList());
      }

      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
          query = query.orderBy('isFeatured', descending: true);
          break;
        case SortOption.newestFirst:
          query = query.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('createdAt', descending: false);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('followerCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('followerCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      List<ArtistProfileModel> artists = snapshot.docs.map((doc) {
        final userType = UserType.fromString(
            doc.get('userType') as String? ?? UserType.artist.name);

        return ArtistProfileModel(
          id: doc.id,
          userId: doc.get('userId'),
          displayName: doc.get('displayName'),
          bio: doc.get('bio'),
          userType: userType,
          location: doc.get('location'),
          mediums: List<String>.from(doc.get('mediums') ?? []),
          styles: List<String>.from(doc.get('styles') ?? []),
          profileImageUrl: doc.get('profileImageUrl'),
          coverImageUrl: doc.get('coverImageUrl'),
          socialLinks: Map<String, String>.from(doc.get('socialLinks') ?? {}),
          isVerified: doc.get('isVerified') ?? false,
          isFeatured: doc.get('isFeatured') ?? false,
          subscriptionTier: SubscriptionTier.values.firstWhere(
              (t) => t.name == (doc.get('subscriptionTier') ?? 'artistBasic'),
              orElse: () => SubscriptionTier.artistBasic),
          createdAt: (doc.get('createdAt') as Timestamp).toDate(),
          updatedAt: (doc.get('updatedAt') as Timestamp).toDate(),
        );
      }).toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        artists = artists.where((artist) {
          return artist.displayName.toLowerCase().contains(searchLower) ||
              (artist.bio?.toLowerCase() ?? '').contains(searchLower) ||
              artist.mediums.any(
                  (medium) => medium.toLowerCase().contains(searchLower)) ||
              artist.styles
                  .any((style) => style.toLowerCase().contains(searchLower));
        }).toList();
      }

      return artists;
    } catch (e, stackTrace) {
      debugPrint('Error filtering artists: $e\n$stackTrace');
      return [];
    }
  }

  /// Filter artworks based on parameters
  Future<List<ArtworkModel>> filterArtwork(FilterParameters params) async {
    try {
      Query query = _firestore.collection('artwork');

      // Apply base filters
      if (params.artMediums?.isNotEmpty ?? false) {
        query = query.where('medium',
            whereIn: params.artMediums!.map((m) => m.name).toList());
      }

      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply date range filters if specified
      if (params.startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(params.startDate!));
      }
      if (params.endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(params.endDate!));
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
          query = query.orderBy('viewCount', descending: true);
          break;
        case SortOption.newestFirst:
          query = query.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('createdAt', descending: false);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('likeCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('likeCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      List<ArtworkModel> artworks = snapshot.docs.map((doc) {
        return ArtworkModel(
          id: doc.id,
          userId: doc.get('userId'),
          artistProfileId: doc.get('artistProfileId'),
          title: doc.get('title'),
          description: doc.get('description'),
          imageUrl: doc.get('imageUrl'),
          medium: doc.get('medium'),
          styles: List<String>.from(doc.get('styles')),
          dimensions: doc.get('dimensions'),
          materials: doc.get('materials'),
          location: doc.get('location'),
          tags: doc.get('tags') != null
              ? List<String>.from(doc.get('tags'))
              : null,
          price: doc.get('price')?.toDouble(),
          isForSale: doc.get('isForSale') ?? false,
          isSold: doc.get('isSold') ?? false,
          yearCreated: doc.get('yearCreated'),
          createdAt: (doc.get('createdAt') as Timestamp).toDate(),
          updatedAt: (doc.get('updatedAt') as Timestamp).toDate(),
        );
      }).toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        artworks = artworks.where((artwork) {
          return artwork.title.toLowerCase().contains(searchLower) ||
              artwork.description.toLowerCase().contains(searchLower) ||
              artwork.medium.toLowerCase().contains(searchLower) ||
              (artwork.tags
                      ?.any((tag) => tag.toLowerCase().contains(searchLower)) ??
                  false);
        }).toList();
      }

      // Apply tag filters in memory
      if (params.tags?.isNotEmpty ?? false) {
        artworks = artworks.where((artwork) {
          return artwork.tags?.any((tag) => params.tags!.contains(tag)) ??
              false;
        }).toList();
      }

      return artworks;
    } catch (e, stackTrace) {
      debugPrint('Error filtering artwork: $e\n$stackTrace');
      return [];
    }
  }

  /// Filter events based on parameters
  Future<List<EventModel>> filterEvents(FilterParameters params) async {
    try {
      Query query = _firestore.collection('events');

      // Apply location filter
      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply date range filters
      if (params.startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(params.startDate!));
      }
      if (params.endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(params.endDate!));
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
        case SortOption.newestFirst:
          query = query.orderBy('startDate', descending: false);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('startDate', descending: true);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('interestedCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('interestedCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      List<EventModel> events = snapshot.docs.map((doc) {
        return EventModel(
          id: doc.id,
          title: doc.get('title'),
          description: doc.get('description'),
          startDate: (doc.get('startDate') as Timestamp).toDate(),
          endDate: doc.get('endDate') != null
              ? (doc.get('endDate') as Timestamp).toDate()
              : null,
          location: doc.get('location'),
          imageUrl: doc.get('imageUrl'),
          artistId: doc.get('artistId'),
          isPublic: doc.get('isPublic') ?? true,
          attendeeIds: List<String>.from(doc.get('attendeeIds') ?? []),
          createdAt: (doc.get('createdAt') as Timestamp).toDate(),
          updatedAt: (doc.get('updatedAt') as Timestamp).toDate(),
        );
      }).toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        events = events.where((event) {
          return event.title.toLowerCase().contains(searchLower) ||
              event.description.toLowerCase().contains(searchLower) ||
              event.location.toLowerCase().contains(searchLower);
        }).toList();
      }

      return events;
    } catch (e, stackTrace) {
      debugPrint('Error filtering events: $e\n$stackTrace');
      return [];
    }
  }
}
