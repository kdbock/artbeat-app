import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for tracking artist analytics data
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _artworkViewsCollection =
      FirebaseFirestore.instance.collection('artworkViews');
  final CollectionReference _artistProfileViewsCollection =
      FirebaseFirestore.instance.collection('artistProfileViews');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Track an artwork view
  Future<void> trackArtworkView({
    required String artworkId,
    required String artistId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      // Allow anonymous tracking for public views
      return;
    }

    // Don't track if the artist is viewing their own artwork
    if (userId == artistId) {
      return;
    }

    try {
      // Check if this user has already viewed this artwork recently (last 24 hours)
      final viewsSnapshot = await _artworkViewsCollection
          .where('artworkId', isEqualTo: artworkId)
          .where('viewerId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 24)),
              ))
          .limit(1)
          .get();

      // Only record a new view if there's no recent view from this user
      if (viewsSnapshot.docs.isEmpty) {
        await _artworkViewsCollection.add({
          'artworkId': artworkId,
          'artistId': artistId,
          'viewerId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Update view count in artwork document
        await _firestore.collection('artwork').doc(artworkId).update({
          'viewCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error tracking artwork view: $e');
    }
  }

  /// Track an artist profile view
  Future<void> trackArtistProfileView({
    required String artistProfileId,
    required String artistId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      // Allow anonymous tracking for public views
      return;
    }

    // Don't track if the artist is viewing their own profile
    if (userId == artistId) {
      return;
    }

    try {
      // Check if this user has already viewed this profile recently (last 24 hours)
      final viewsSnapshot = await _artistProfileViewsCollection
          .where('artistProfileId', isEqualTo: artistProfileId)
          .where('viewerId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 24)),
              ))
          .limit(1)
          .get();

      // Only record a new view if there's no recent view from this user
      if (viewsSnapshot.docs.isEmpty) {
        await _artistProfileViewsCollection.add({
          'artistProfileId': artistProfileId,
          'artistId': artistId,
          'viewerId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error tracking artist profile view: $e');
    }
  }

  /// Get artwork analytics for the specified artist
  Future<Map<String, dynamic>> getArtworkAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get view counts for the specified date range
      final viewsSnapshot = await _artworkViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Total views in period
      result['totalViews'] = viewsSnapshot.docs.length;

      // Views by artwork
      final viewsByArtwork = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final artworkId = data['artworkId'] as String;
        viewsByArtwork[artworkId] = (viewsByArtwork[artworkId] ?? 0) + 1;
      }
      result['viewsByArtwork'] = viewsByArtwork;

      // Views by day
      final viewsByDay = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final viewDate = (data['viewedAt'] as Timestamp).toDate();
        final dayString =
            '${viewDate.year}-${viewDate.month.toString().padLeft(2, '0')}-${viewDate.day.toString().padLeft(2, '0')}';
        viewsByDay[dayString] = (viewsByDay[dayString] ?? 0) + 1;
      }
      result['viewsByDay'] = viewsByDay;
    } catch (e) {
      print('Error getting artwork analytics: $e');
    }

    return result;
  }

  /// Get artist profile analytics for the specified artist
  Future<Map<String, dynamic>> getProfileAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get profile view counts for the specified date range
      final viewsSnapshot = await _artistProfileViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Total profile views in period
      result['totalProfileViews'] = viewsSnapshot.docs.length;

      // Views by day
      final viewsByDay = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final viewDate = (data['viewedAt'] as Timestamp).toDate();
        final dayString =
            '${viewDate.year}-${viewDate.month.toString().padLeft(2, '0')}-${viewDate.day.toString().padLeft(2, '0')}';
        viewsByDay[dayString] = (viewsByDay[dayString] ?? 0) + 1;
      }
      result['profileViewsByDay'] = viewsByDay;

      // Get unique viewers count
      final uniqueViewers = viewsSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['viewerId'] as String)
          .toSet()
          .length;
      result['uniqueViewers'] = uniqueViewers;
    } catch (e) {
      print('Error getting profile analytics: $e');
    }

    return result;
  }

  /// Get follower analytics
  Future<Map<String, dynamic>> getFollowerAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get all followers
      final followersSnapshot = await _firestore
          .collection('artistFollowers')
          .doc(userId)
          .collection('followers')
          .get();

      // Total followers
      result['totalFollowers'] = followersSnapshot.docs.length;

      // New followers in period
      final newFollowersSnapshot = await _firestore
          .collection('artistFollowers')
          .doc(userId)
          .collection('followers')
          .where('followedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('followedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      result['newFollowers'] = newFollowersSnapshot.docs.length;

      // Followers by day
      final followersByDay = <String, int>{};
      for (final doc in newFollowersSnapshot.docs) {
        final data = doc.data();
        if (data['followedAt'] != null) {
          final followDate = (data['followedAt'] as Timestamp).toDate();
          final dayString =
              '${followDate.year}-${followDate.month.toString().padLeft(2, '0')}-${followDate.day.toString().padLeft(2, '0')}';
          followersByDay[dayString] = (followersByDay[dayString] ?? 0) + 1;
        }
      }
      result['followersByDay'] = followersByDay;
    } catch (e) {
      print('Error getting follower analytics: $e');
    }

    return result;
  }

  /// Get gallery analytics overview
  Future<Map<String, dynamic>> getGalleryAnalytics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(galleryData['galleryArtists'] ?? []);
      result['totalArtists'] = artistIds.length;

      // Get total artworks
      int totalArtworks = 0;
      int totalViews = 0;
      int totalSales = 0;
      double totalRevenue = 0.0;
      double totalCommission = 0.0;

      // Fetch artwork analytics for each artist
      for (final artistId in artistIds) {
        // Get artwork count
        final artworksSnapshot = await _firestore
            .collection('artwork')
            .where('artistId', isEqualTo: artistId)
            .get();

        totalArtworks += artworksSnapshot.docs.length;

        // Get views
        final viewsSnapshot = await _artworkViewsCollection
            .where('artistId', isEqualTo: artistId)
            .where('viewedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        totalViews += viewsSnapshot.docs.length;

        // Get sales data
        final salesSnapshot = await _firestore
            .collection('sales')
            .where('artistId', isEqualTo: artistId)
            .where('saleDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        totalSales +=
            salesSnapshot.docs.length; // Calculate revenue and commission
        for (final saleDoc in salesSnapshot.docs) {
          final saleData = saleDoc.data();
          final saleAmount = (saleData['amount'] as num).toDouble();
          final commissionRate =
              (saleData['commissionRate'] as num?)?.toDouble() ?? 0.0;

          totalRevenue += saleAmount;
          totalCommission += (saleAmount * commissionRate / 100);
        }
      }

      // Calculate views to sales rate
      double viewsToSalesRate = 0.0;
      if (totalViews > 0) {
        viewsToSalesRate = (totalSales / totalViews) * 100;
      }

      // Set results
      result['totalArtworks'] = totalArtworks;
      result['totalViews'] = totalViews;
      result['totalSales'] = totalSales;
      result['totalRevenue'] = totalRevenue;
      result['totalCommission'] = totalCommission;
      result['viewsToSalesRate'] = viewsToSalesRate;
    } catch (e) {
      print('Error getting gallery analytics: $e');
      throw Exception('Failed to load gallery analytics: $e');
    }

    return result;
  }

  /// Get artist performance analytics for gallery
  Future<List<Map<String, dynamic>>> getArtistPerformanceAnalytics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <Map<String, dynamic>>[];

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(galleryData['galleryArtists'] ?? []);

      // Fetch performance data for each artist
      for (final artistId in artistIds) {
        final artistData = <String, dynamic>{};

        // Get artist profile
        final artistDoc =
            await _firestore.collection('artistProfiles').doc(artistId).get();

        if (artistDoc.exists) {
          final profile = artistDoc.data() as Map<String, dynamic>;
          artistData['artistId'] = artistId;
          artistData['displayName'] = profile['displayName'];
          artistData['profileImageUrl'] = profile['profileImageUrl'];
          artistData['location'] = profile['location'];

          // Get artwork views
          final viewsSnapshot = await _artworkViewsCollection
              .where('artistId', isEqualTo: artistId)
              .where('viewedAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('viewedAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get();

          artistData['artworkViews'] = viewsSnapshot.docs.length;

          // Get sales data
          final salesSnapshot = await _firestore
              .collection('sales')
              .where('artistId', isEqualTo: artistId)
              .where('saleDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('saleDate',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get();

          artistData['sales'] = salesSnapshot.docs.length;

          // Calculate revenue and commission
          double revenue = 0.0;
          double commission = 0.0;

          for (final saleDoc in salesSnapshot.docs) {
            final saleData = saleDoc.data();
            final saleAmount = (saleData['amount'] as num).toDouble();
            final commissionRate =
                (saleData['commissionRate'] as num?)?.toDouble() ?? 0.0;

            revenue += saleAmount;
            commission += (saleAmount * commissionRate / 100);
          }

          artistData['revenue'] = revenue;
          artistData['commission'] = commission;

          result.add(artistData);
        }
      }

      // Sort by revenue in descending order
      result.sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    } catch (e) {
      print('Error getting artist performance analytics: $e');
      throw Exception('Failed to load artist performance analytics: $e');
    }

    return result;
  }

  /// Get commission metrics for gallery
  Future<Map<String, dynamic>> getCommissionMetrics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get commission records
      final commissionsSnapshot = await _firestore
          .collection('commissions')
          .where('galleryId', isEqualTo: galleryProfileId)
          .get();

      // Calculate average commission rate
      double totalRate = 0.0;
      double pendingCommission = 0.0;
      double paidCommission = 0.0;

      for (final doc in commissionsSnapshot.docs) {
        final data = doc.data();
        final commissionRate = (data['commissionRate'] as num).toDouble();
        totalRate += commissionRate;

        // Calculate pending and paid commissions
        if (data['transactions'] != null) {
          final transactions =
              List<Map<String, dynamic>>.from(data['transactions']);
          for (final transaction in transactions) {
            final amount = (transaction['commissionAmount'] as num).toDouble();

            if (transaction['status'] == 'pending') {
              pendingCommission += amount;
            } else if (transaction['status'] == 'paid') {
              paidCommission += amount;
            }
          }
        }
      }

      // Calculate average
      double avgCommissionRate = 0.0;
      if (commissionsSnapshot.docs.isNotEmpty) {
        avgCommissionRate = totalRate / commissionsSnapshot.docs.length;
      }

      result['avgCommissionRate'] = avgCommissionRate;
      result['pendingCommission'] = pendingCommission;
      result['paidCommission'] = paidCommission;
    } catch (e) {
      print('Error getting commission metrics: $e');
      throw Exception('Failed to load commission metrics: $e');
    }

    return result;
  }

  /// Get revenue timeline data for chart
  Future<List<Map<String, dynamic>>> getRevenueTimelineData({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy, // 'day' or 'month'
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <Map<String, dynamic>>[];

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(galleryData['galleryArtists'] ?? []);

      // Create a map to store revenue by date
      final revenueByDate = <String, double>{};

      // Get sales data for each artist
      for (final artistId in artistIds) {
        final salesSnapshot = await _firestore
            .collection('sales')
            .where('artistId', isEqualTo: artistId)
            .where('saleDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        for (final saleDoc in salesSnapshot.docs) {
          final saleData = saleDoc.data();
          final saleDate = (saleData['saleDate'] as Timestamp).toDate();
          final saleAmount = (saleData['amount'] as num).toDouble();

          // Format date key based on groupBy parameter
          String dateKey;
          if (groupBy == 'day') {
            dateKey =
                '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}';
          } else {
            dateKey =
                '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';
          }

          // Add revenue to date
          revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0.0) + saleAmount;
        }
      }

      // Generate a complete date range
      DateTime current =
          DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        String dateKey;
        if (groupBy == 'day') {
          dateKey =
              '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        } else {
          dateKey =
              '${current.year}-${current.month.toString().padLeft(2, '0')}';
          // Skip to next month
          current = DateTime(current.year, current.month + 1, 1);
          continue;
        }

        result.add({
          'date': current,
          'dateKey': dateKey,
          'revenue': revenueByDate[dateKey] ?? 0.0,
        });

        // Move to next day
        current = current.add(const Duration(days: 1));
      }

      // Sort results by date
      result.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    } catch (e) {
      print('Error getting revenue timeline data: $e');
      throw Exception('Failed to load revenue timeline data: $e');
    }

    return result;
  }
}
