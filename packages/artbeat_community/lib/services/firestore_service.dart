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
        name: data['name'],
        description: data['description'],
        tags: List<String>.from(data['tags'] ?? []),
        privacyType: data['privacyType'],
        memberList: List<String>.from(data['memberList'] ?? []),
        createdAt: data['createdAt'] ?? Timestamp.now(),
        updatedAt: data['updatedAt'] ?? Timestamp.now(),
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

  Future<void> deleteStudio(String studioId) async {
    await _firestore.collection('studios').doc(studioId).delete();
  }
}
