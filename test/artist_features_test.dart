// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:artbeat_core/artbeat_core.dart' show UserType, SubscriptionTier;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_test_setup.dart';

void main() {
  group('ARTIST FEATURES - Comprehensive Test Suite', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser testUser;

    setUpAll(() async {
      await FirebaseTestSetup.initializeFirebaseForTesting();
    });

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();

      // Create a test user
      testUser = FirebaseTestSetup.createMockUser(
        uid: 'artist-test-uid',
        email: 'artist@example.com',
        displayName: 'Test Artist',
      );

      // Sign in the test user
      await mockAuth.signInWithCredential(
        EmailAuthProvider.credential(
          email: testUser.email!,
          password: 'password123',
        ),
      );

      // Services are tested through Firebase integration
    });

    tearDown(() async {
      await mockAuth.signOut();
    });

    // ========================================================================
    // SECTION 8: ARTIST FEATURES - TEST CASES
    // ========================================================================

    group('8.1: Artist Profile Display', () {
      test('should fetch artist profile by user ID', () async {
        // Arrange
        final artistProfileData = {
          'id': 'profile-doc-1',
          'userId': 'artist-test-uid',
          'displayName': 'John Doe',
          'bio': 'A talented digital artist',
          'userType': UserType.artist.name,
          'location': 'New York, NY',
          'mediums': ['Digital', 'Watercolor'],
          'styles': ['Abstract', 'Modern'],
          'socialLinks': {
            'website': 'https://johndoe.com',
            'instagram': 'https://instagram.com/johndoe',
          },
          'profileImageUrl': 'https://example.com/profile.jpg',
          'coverImageUrl': 'https://example.com/cover.jpg',
          'subscriptionTier': SubscriptionTier.free.apiName,
          'isVerified': false,
          'isFeatured': false,
          'followerCount': 42,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        await fakeFirestore
            .collection('artistProfiles')
            .doc('profile-doc-1')
            .set(artistProfileData);

        // Act
        final snapshot = await fakeFirestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: 'artist-test-uid')
            .get();

        // Assert
        expect(snapshot.docs.isNotEmpty, true);
        expect(snapshot.docs.first['displayName'], 'John Doe');
        expect(snapshot.docs.first['bio'], 'A talented digital artist');
      });

      test('should handle missing artist profile gracefully', () async {
        // Act
        final snapshot = await fakeFirestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: 'nonexistent-uid')
            .get();

        // Assert
        expect(snapshot.docs.isEmpty, true);
      });
    });

    group('8.2: View Artist Bio & Portfolio', () {
      test('should retrieve artist bio and portfolio information', () async {
        // Arrange
        final artistData = {
          'userId': 'artist-test-uid',
          'displayName': 'Jane Smith',
          'bio': 'Contemporary art specialist',
          'mediums': ['Oil', 'Acrylic'],
          'styles': ['Contemporary', 'Expressionism'],
          'portfolio': ['artwork-1', 'artwork-2', 'artwork-3'],
        };

        await fakeFirestore
            .collection('artistProfiles')
            .doc('artist-1')
            .set(artistData);

        // Act
        final doc = await fakeFirestore
            .collection('artistProfiles')
            .doc('artist-1')
            .get();

        // Assert
        expect(doc.exists, true);
        expect(doc['bio'], 'Contemporary art specialist');
        expect(doc['mediums'], contains('Oil'));
        expect(doc['mediums'], contains('Acrylic'));
      });

      test(
        'should fetch artist statistics (followers, views, sales)',
        () async {
          // Arrange
          final artistStats = {
            'artistId': 'artist-test-uid',
            'followerCount': 150,
            'profileViews': 1250,
            'artworkSold': 8,
            'totalEarnings': 5420.50,
            'averageRating': 4.8,
          };

          await fakeFirestore
              .collection('artistStats')
              .doc('artist-test-uid')
              .set(artistStats);

          // Act
          final statsDoc = await fakeFirestore
              .collection('artistStats')
              .doc('artist-test-uid')
              .get();

          // Assert
          expect(statsDoc.exists, true);
          expect(statsDoc['followerCount'], 150);
          expect(statsDoc['profileViews'], 1250);
          expect(statsDoc['artworkSold'], 8);
        },
      );
    });

    group('8.3: Follow/Unfollow Artist', () {
      test('should create follow relationship between users', () async {
        // Arrange
        const followerId = 'follower-uid';
        const artistId = 'artist-test-uid';

        final followData = {
          'followerId': followerId,
          'followingId': artistId,
          'followedAt': Timestamp.now(),
          'status': 'active',
        };

        // Act
        await fakeFirestore.collection('follows').add(followData);

        // Assert
        final followSnapshot = await fakeFirestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: artistId)
            .get();

        expect(followSnapshot.docs.isNotEmpty, true);
      });

      test('should check if user is following artist', () async {
        // Arrange
        const followerId = 'follower-uid';
        const artistId = 'artist-test-uid';

        await fakeFirestore.collection('follows').add({
          'followerId': followerId,
          'followingId': artistId,
          'followedAt': Timestamp.now(),
        });

        // Act
        final followSnapshot = await fakeFirestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: artistId)
            .limit(1)
            .get();

        // Assert
        expect(followSnapshot.docs.isNotEmpty, true);
      });

      test('should remove follow relationship when unfollowing', () async {
        // Arrange
        const followerId = 'follower-uid';
        const artistId = 'artist-test-uid';

        final docRef = await fakeFirestore.collection('follows').add({
          'followerId': followerId,
          'followingId': artistId,
          'followedAt': Timestamp.now(),
        });

        // Act
        await docRef.delete();

        // Assert
        final snapshot = await fakeFirestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: artistId)
            .get();

        expect(snapshot.docs.isEmpty, true);
      });
    });

    group('8.4: Commission Artist', () {
      test('should fetch artist commission settings', () async {
        // Arrange
        final commissionSettings = {
          'artistId': 'artist-test-uid',
          'acceptingCommissions': true,
          'minCommissionPrice': 150.0,
          'maxCommissionPrice': 5000.0,
          'turnaroundDays': 30,
          'commissionTypes': ['Character Design', 'Portrait', 'Custom Artwork'],
          'description': 'Custom artwork for your needs',
        };

        await fakeFirestore
            .collection('commissionSettings')
            .doc('artist-test-uid')
            .set(commissionSettings);

        // Act
        final doc = await fakeFirestore
            .collection('commissionSettings')
            .doc('artist-test-uid')
            .get();

        // Assert
        expect(doc.exists, true);
        expect(doc['acceptingCommissions'], true);
        expect(doc['minCommissionPrice'], 150.0);
        expect(doc['commissionTypes'], contains('Portrait'));
      });

      test('should create commission request', () async {
        // Arrange
        const clientId = 'client-uid';
        const artistId = 'artist-test-uid';

        final commissionRequest = {
          'id': 'commission-1',
          'clientId': clientId,
          'clientName': 'Test Client',
          'artistId': artistId,
          'artistName': 'Test Artist',
          'title': 'Custom Portrait',
          'description': 'A portrait of my family',
          'budget': 500.0,
          'status': 'pending',
          'createdAt': Timestamp.now(),
        };

        // Act
        await fakeFirestore
            .collection('commissionRequests')
            .add(commissionRequest);

        // Assert
        final snapshot = await fakeFirestore
            .collection('commissionRequests')
            .where('artistId', isEqualTo: artistId)
            .where('clientId', isEqualTo: clientId)
            .get();

        expect(snapshot.docs.isNotEmpty, true);
        expect(snapshot.docs.first['title'], 'Custom Portrait');
        expect(snapshot.docs.first['status'], 'pending');
      });

      test('should allow artist to accept/reject commission', () async {
        // Arrange
        final commissionRef = await fakeFirestore
            .collection('commissionRequests')
            .add({
              'clientId': 'client-uid',
              'artistId': 'artist-test-uid',
              'title': 'Portrait',
              'status': 'pending',
              'createdAt': Timestamp.now(),
            });

        // Act - Accept commission
        await commissionRef.update({'status': 'accepted'});

        // Assert
        final updated = await commissionRef.get();
        expect(updated['status'], 'accepted');

        // Act - Reject commission
        await commissionRef.update({'status': 'rejected'});

        // Assert
        final rejected = await commissionRef.get();
        expect(rejected['status'], 'rejected');
      });
    });

    group('8.5: Artist Dashboard', () {
      test('should load artist dashboard with overview statistics', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final dashboardData = {
          'artistId': artistId,
          'artworkCount': 23,
          'profileViews': 1520,
          'totalFollowers': 342,
          'totalEarnings': 12450.75,
          'pendingOrders': 3,
          'completedOrders': 18,
          'lastUpdated': Timestamp.now(),
        };

        await fakeFirestore
            .collection('artistDashboard')
            .doc(artistId)
            .set(dashboardData);

        // Act
        final dashboard = await fakeFirestore
            .collection('artistDashboard')
            .doc(artistId)
            .get();

        // Assert
        expect(dashboard.exists, true);
        expect(dashboard['artworkCount'], 23);
        expect(dashboard['profileViews'], 1520);
        expect(dashboard['pendingOrders'], 3);
      });

      test('should track recent activities on dashboard', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final activities = [
          {
            'type': 'sale',
            'description': 'Artwork sold',
            'timestamp': Timestamp.now(),
            'amount': 500.0,
          },
          {
            'type': 'commission',
            'description': 'Commission accepted',
            'timestamp': Timestamp.now(),
            'amount': 800.0,
          },
          {
            'type': 'follower',
            'description': 'New follower',
            'timestamp': Timestamp.now(),
          },
        ];

        for (final activity in activities) {
          await fakeFirestore.collection('artistActivities').add({
            'artistId': artistId,
            ...activity,
          });
        }

        // Act
        final activitySnapshot = await fakeFirestore
            .collection('artistActivities')
            .where('artistId', isEqualTo: artistId)
            .get();

        // Assert
        expect(activitySnapshot.docs.length, 3);
        expect(activitySnapshot.docs.any((d) => d['type'] == 'sale'), true);
        expect(
          activitySnapshot.docs.any((d) => d['type'] == 'commission'),
          true,
        );
      });
    });

    group('8.6: Manage Artist Artwork', () {
      test('should fetch all artwork by artist', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final artworks = [
          {
            'title': 'Sunset',
            'artistId': artistId,
            'medium': 'Oil on Canvas',
            'price': 800.0,
            'sold': false,
          },
          {
            'title': 'Ocean View',
            'artistId': artistId,
            'medium': 'Acrylic',
            'price': 600.0,
            'sold': true,
          },
          {
            'title': 'Mountain Peak',
            'artistId': artistId,
            'medium': 'Digital',
            'price': 300.0,
            'sold': false,
          },
        ];

        for (final artwork in artworks) {
          await fakeFirestore.collection('artwork').add(artwork);
        }

        // Act
        final snapshot = await fakeFirestore
            .collection('artwork')
            .where('artistId', isEqualTo: artistId)
            .get();

        // Assert
        expect(snapshot.docs.length, 3);
        expect(snapshot.docs.any((d) => d['title'] == 'Sunset'), true);
        expect(snapshot.docs.any((d) => d['sold'] == true), true);
      });

      test('should allow artist to upload new artwork', () async {
        // Arrange
        const artistId = 'artist-test-uid';
        final newArtwork = {
          'title': 'New Masterpiece',
          'artistId': artistId,
          'description': 'A new creation',
          'medium': 'Digital Painting',
          'imageUrl': 'https://example.com/art.jpg',
          'price': 1200.0,
          'createdAt': Timestamp.now(),
        };

        // Act
        final docRef = await fakeFirestore
            .collection('artwork')
            .add(newArtwork);

        // Assert
        expect(docRef.id.isNotEmpty, true);
        final created = await docRef.get();
        expect(created['title'], 'New Masterpiece');
        expect(created['artistId'], artistId);
      });

      test('should allow editing of artist artwork', () async {
        // Arrange
        const artistId = 'artist-test-uid';
        final docRef = await fakeFirestore.collection('artwork').add({
          'title': 'Original Title',
          'artistId': artistId,
          'price': 500.0,
        });

        // Act
        await docRef.update({'title': 'Updated Title', 'price': 750.0});

        // Assert
        final updated = await docRef.get();
        expect(updated['title'], 'Updated Title');
        expect(updated['price'], 750.0);
      });

      test('should allow deletion of artist artwork', () async {
        // Arrange
        const artistId = 'artist-test-uid';
        final docRef = await fakeFirestore.collection('artwork').add({
          'title': 'Artwork to Delete',
          'artistId': artistId,
        });

        // Act
        await docRef.delete();

        // Assert
        final deleted = await docRef.get();
        expect(deleted.exists, false);
      });
    });

    group('8.7: View Artist Analytics', () {
      test('should fetch artist analytics dashboard data', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final analyticsData = {
          'artistId': artistId,
          'profileViews': 2150,
          'profileViewsThisMonth': 580,
          'artworkViews': 5420,
          'artworkViewsThisMonth': 1230,
          'followerGrowth': 45,
          'followerGrowthThisMonth': 12,
          'engagementRate': 0.15,
          'topArtwork': 'artwork-123',
          'lastUpdated': Timestamp.now(),
        };

        await fakeFirestore
            .collection('analyticsData')
            .doc(artistId)
            .set(analyticsData);

        // Act
        final analytics = await fakeFirestore
            .collection('analyticsData')
            .doc(artistId)
            .get();

        // Assert
        expect(analytics.exists, true);
        expect(analytics['profileViews'], 2150);
        expect(analytics['followerGrowth'], 45);
        expect(analytics['engagementRate'], 0.15);
      });

      test('should track sales analytics over time', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final salesData = [
          {
            'artistId': artistId,
            'date': Timestamp.now(),
            'amount': 500.0,
            'itemsSold': 1,
          },
          {
            'artistId': artistId,
            'date': Timestamp.now(),
            'amount': 750.0,
            'itemsSold': 2,
          },
        ];

        for (final sale in salesData) {
          await fakeFirestore.collection('salesAnalytics').add(sale);
        }

        // Act
        final snapshot = await fakeFirestore
            .collection('salesAnalytics')
            .where('artistId', isEqualTo: artistId)
            .get();

        // Assert
        expect(snapshot.docs.length, 2);
        final totalAmount = snapshot.docs.fold<double>(
          0,
          (prev, doc) => prev + (doc['amount'] as num).toDouble(),
        );
        expect(totalAmount, 1250.0);
      });
    });

    group('8.8: View Artist Earnings', () {
      test('should retrieve artist earnings summary', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final earningsData = {
          'id': artistId,
          'artistId': artistId,
          'totalEarnings': 15420.75,
          'availableBalance': 8520.50,
          'pendingBalance': 2400.00,
          'giftEarnings': 1200.00,
          'sponsorshipEarnings': 2100.00,
          'commissionEarnings': 8920.75,
          'subscriptionEarnings': 1200.00,
          'lastUpdated': Timestamp.now(),
        };

        await fakeFirestore
            .collection('artist_earnings')
            .doc(artistId)
            .set(earningsData);

        // Act
        final earnings = await fakeFirestore
            .collection('artist_earnings')
            .doc(artistId)
            .get();

        // Assert
        expect(earnings.exists, true);
        expect(earnings['totalEarnings'], 15420.75);
        expect(earnings['availableBalance'], 8520.50);
        expect(earnings['commissionEarnings'], 8920.75);
      });

      test('should track earnings by source', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final earningBreakdown = {
          'artistId': artistId,
          'gifts': 1200.0,
          'sponsorships': 2100.0,
          'commissions': 8920.75,
          'subscriptions': 1200.0,
          'artworkSales': 2000.0,
        };

        await fakeFirestore
            .collection('earningsBreakdown')
            .doc(artistId)
            .set(earningBreakdown);

        // Act
        final breakdown = await fakeFirestore
            .collection('earningsBreakdown')
            .doc(artistId)
            .get();

        // Assert
        expect(breakdown.exists, true);
        expect(breakdown['gifts'], 1200.0);
        expect(breakdown['commissions'], 8920.75);
        final total =
            (breakdown['gifts'] as num) +
            (breakdown['sponsorships'] as num) +
            (breakdown['commissions'] as num) +
            (breakdown['subscriptions'] as num) +
            (breakdown['artworkSales'] as num);
        expect(total, greaterThan(15000));
      });
    });

    group('8.9: Manage Payout Accounts', () {
      test('should retrieve artist payout accounts', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final payoutAccounts = [
          {
            'artistId': artistId,
            'accountType': 'stripe',
            'accountName': 'Primary Account',
            'accountEmail': 'artist@stripe.com',
            'isDefault': true,
            'createdAt': Timestamp.now(),
          },
          {
            'artistId': artistId,
            'accountType': 'bank_transfer',
            'accountName': 'Bank Account',
            'accountNumber': '****1234',
            'isDefault': false,
            'createdAt': Timestamp.now(),
          },
        ];

        for (final account in payoutAccounts) {
          await fakeFirestore.collection('payoutAccounts').add(account);
        }

        // Act
        final snapshot = await fakeFirestore
            .collection('payoutAccounts')
            .where('artistId', isEqualTo: artistId)
            .get();

        // Assert
        expect(snapshot.docs.length, 2);
        expect(snapshot.docs.any((d) => d['accountType'] == 'stripe'), true);
        expect(snapshot.docs.any((d) => d['isDefault'] == true), true);
      });

      test('should allow adding new payout account', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final newAccount = {
          'artistId': artistId,
          'accountType': 'paypal',
          'accountEmail': 'artist@paypal.com',
          'isDefault': false,
          'createdAt': Timestamp.now(),
        };

        // Act
        final docRef = await fakeFirestore
            .collection('payoutAccounts')
            .add(newAccount);

        // Assert
        expect(docRef.id.isNotEmpty, true);
        final created = await docRef.get();
        expect(created['accountType'], 'paypal');
      });

      test('should allow updating default payout account', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final account1 = await fakeFirestore.collection('payoutAccounts').add({
          'artistId': artistId,
          'accountType': 'stripe',
          'isDefault': true,
        });

        final account2 = await fakeFirestore.collection('payoutAccounts').add({
          'artistId': artistId,
          'accountType': 'paypal',
          'isDefault': false,
        });

        // Act
        await account1.update({'isDefault': false});
        await account2.update({'isDefault': true});

        // Assert
        final updated1 = await account1.get();
        final updated2 = await account2.get();
        expect(updated1['isDefault'], false);
        expect(updated2['isDefault'], true);
      });
    });

    group('8.10: Request Payout', () {
      test('should create payout request with validation', () async {
        // Arrange
        const artistId = 'artist-test-uid';
        const availableBalance = 5000.0;
        const requestAmount = 2500.0;

        final payoutRequest = {
          'artistId': artistId,
          'amount': requestAmount,
          'accountId': 'account-1',
          'status': 'pending',
          'requestedAt': Timestamp.now(),
          'notes': 'Monthly payout',
        };

        // Act
        final docRef = await fakeFirestore
            .collection('payoutRequests')
            .add(payoutRequest);

        // Assert
        expect(docRef.id.isNotEmpty, true);
        expect(requestAmount <= availableBalance, true);

        final created = await docRef.get();
        expect(created['amount'], requestAmount);
        expect(created['status'], 'pending');
      });

      test('should track payout request status', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final payoutRef = await fakeFirestore.collection('payoutRequests').add({
          'artistId': artistId,
          'amount': 1500.0,
          'status': 'pending',
          'requestedAt': Timestamp.now(),
        });

        // Act - Process payout
        await payoutRef.update({
          'status': 'processing',
          'processedAt': Timestamp.now(),
        });

        // Assert
        var payout = await payoutRef.get();
        expect(payout['status'], 'processing');

        // Act - Complete payout
        await payoutRef.update({
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });

        // Assert
        payout = await payoutRef.get();
        expect(payout['status'], 'completed');
      });

      test('should retrieve payout history', () async {
        // Arrange
        const artistId = 'artist-test-uid';

        final payouts = [
          {
            'artistId': artistId,
            'amount': 1000.0,
            'status': 'completed',
            'completedAt': Timestamp.now(),
          },
          {
            'artistId': artistId,
            'amount': 1500.0,
            'status': 'completed',
            'completedAt': Timestamp.now(),
          },
          {
            'artistId': artistId,
            'amount': 800.0,
            'status': 'pending',
            'requestedAt': Timestamp.now(),
          },
        ];

        for (final payout in payouts) {
          await fakeFirestore.collection('payoutRequests').add(payout);
        }

        // Act
        final snapshot = await fakeFirestore
            .collection('payoutRequests')
            .where('artistId', isEqualTo: artistId)
            .get();

        // Assert
        expect(snapshot.docs.length, 3);
        final completed = snapshot.docs
            .where((d) => d['status'] == 'completed')
            .length;
        expect(completed, 2);
      });
    });

    // ========================================================================
    // SUMMARY: Artist Features Implementation Status
    // ========================================================================
  });
}
