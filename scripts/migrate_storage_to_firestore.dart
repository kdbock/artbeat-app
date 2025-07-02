import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> migrateArtworkStorageToFirestore() async {
  await Firebase.initializeApp();

  final storage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;

  final artworkRoot = storage.ref().child('artwork_images');
  final ListResult userFolders = await artworkRoot.listAll();

  for (final userFolder in userFolders.prefixes) {
    final userId = userFolder.name;
    final ListResult artworkFolders = await userFolder.listAll();

    for (final artworkFolder in artworkFolders.prefixes) {
      final ListResult images = await artworkFolder.listAll();

      for (final imageRef in images.items) {
        final imageUrl = await imageRef.getDownloadURL();
        final metadata = await imageRef.getMetadata();

        // Check if already migrated (skip if Firestore doc exists for this image)
        final existing = await firestore
            .collection('artwork')
            .where('imageUrl', isEqualTo: imageUrl)
            .get();
        if (existing.docs.isNotEmpty) continue;

        // Use metadata or fallback values
        final title = metadata.customMetadata?['title'] ?? imageRef.name;
        final createdAt = metadata.timeCreated ?? DateTime.now();

        await firestore.collection('artwork').add({
          'imageUrl': imageUrl,
          'artistId': userId,
          'title': title,
          'createdAt': Timestamp.fromDate(createdAt),
          'isPublic': true,
          'isSold': false,
          'medium': metadata.customMetadata?['medium'] ?? '',
          'tags': metadata.customMetadata?['tags']?.split(',') ?? [],
          // Add more fields as needed
        });

        debugPrint('Migrated $imageUrl for user $userId');
      }
    }
  }
  debugPrint('Migration complete!');
}
