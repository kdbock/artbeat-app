import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/studio_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<StudioModel>> getStudios() async {
    final querySnapshot = await _firestore.collection('studios').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return StudioModel(
        id: doc.id,
        name: data['name'] as String,
        description: data['description'] as String,
        tags: List<String>.from(data['tags'] as Iterable? ?? []),
        privacyType: data['privacyType'] as String,
        memberList: List<String>.from(data['memberList'] as Iterable? ?? []),
        createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
        updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
      );
    }).toList();
  }

  Future<void> createStudio(StudioModel studio) async {
    await _firestore.collection('studios').add({
      'name': studio.name,
      'description': studio.description,
      'tags': studio.tags,
      'privacyType': studio.privacyType,
      'memberList': studio.memberList,
      'createdAt': studio.createdAt,
      'updatedAt': studio.updatedAt,
    });
  }

  Future<StudioModel?> getStudioById(String studioId) async {
    final doc = await _firestore.collection('studios').doc(studioId).get();
    if (doc.exists) {
      return StudioModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateStudio(StudioModel studio) async {
    await _firestore
        .collection('studios')
        .doc(studio.id)
        .update(studio.toFirestore());
  }

  Future<void> deleteStudio(String studioId) async {
    await _firestore.collection('studios').doc(studioId).delete();
  }
}
