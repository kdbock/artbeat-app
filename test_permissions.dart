import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Sign in the user
  await auth.signInWithEmailAndPassword(
    email: 'kristy.kelly@example.com',
    password: 'password123',
  );

  final userId = auth.currentUser?.uid;
  print('🔑 Current user ID: $userId');

  if (userId != null) {
    print('\n🧪 Testing Firestore permissions...\n');

    // Test artist profile access
    try {
      final artistProfileQuery = await firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      print('✅ Artist profiles: ${artistProfileQuery.docs.length} documents');
    } catch (e) {
      print('❌ Artist profiles error: $e');
    }

    // Test subscription access
    try {
      final subscriptionQuery = await firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      print('✅ Subscriptions: ${subscriptionQuery.docs.length} documents');
    } catch (e) {
      print('❌ Subscriptions error: $e');
    }

    // Test events access (organizer)
    try {
      final now = DateTime.now();
      final eventsQuery = await firestore
          .collection('events')
          .where('artistId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(5)
          .get();
      print('✅ Events (organizer): ${eventsQuery.docs.length} documents');
    } catch (e) {
      print('❌ Events (organizer) error: $e');
    }

    // Test events access (attendee)
    try {
      final now = DateTime.now();
      final eventsQuery = await firestore
          .collection('events')
          .where('attendeeIds', arrayContains: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(5)
          .get();
      print('✅ Events (attendee): ${eventsQuery.docs.length} documents');
    } catch (e) {
      print('❌ Events (attendee) error: $e');
    }

    // Test artwork views access
    try {
      final viewsQuery = await firestore
          .collection('artworkViews')
          .where('artistId', isEqualTo: userId)
          .limit(5)
          .get();
      print('✅ Artwork views: ${viewsQuery.docs.length} documents');
    } catch (e) {
      print('❌ Artwork views error: $e');
    }

    // Test artist profile views access
    try {
      final viewsQuery = await firestore
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .limit(5)
          .get();
      print('✅ Artist profile views: ${viewsQuery.docs.length} documents');
    } catch (e) {
      print('❌ Artist profile views error: $e');
    }

    // Test artwork access
    try {
      final artworkQuery = await firestore
          .collection('artwork')
          .where('artistId', isEqualTo: userId)
          .limit(5)
          .get();
      print('✅ Artwork: ${artworkQuery.docs.length} documents');
    } catch (e) {
      print('❌ Artwork error: $e');
    }

    // Test commissions access
    try {
      final commissionsQuery = await firestore
          .collection('commissions')
          .where('artistId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();
      print('✅ Commissions: ${commissionsQuery.docs.length} documents');
    } catch (e) {
      print('❌ Commissions error: $e');
    }

    print('\n🎯 Permission testing completed!');
  }

  await auth.signOut();
}
