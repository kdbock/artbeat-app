import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

class TestableCaptureService {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'captures';

  TestableCaptureService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<CaptureModel>> getUserCaptures(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .withConverter<CaptureModel>(
            fromFirestore: (snapshot, _) =>
                CaptureModel.fromFirestore(snapshot, null),
            toFirestore: (capture, _) => capture.toFirestore(),
          )
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Log error or handle as needed
      print('Error fetching user captures: $e');
      throw Exception('Failed to load captures.');
    }
  }

  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    if (userId == null) {
      return [];
    }
    return getUserCaptures(userId);
  }

  // Sample of additional methods for testing
  Future<String> createCapture(CaptureModel capture) async {
    try {
      final docRef = await _firestore
          .collection(_collectionPath)
          .withConverter<CaptureModel>(
            fromFirestore: (snapshot, _) =>
                CaptureModel.fromFirestore(snapshot, null),
            toFirestore: (capture, _) => capture.toFirestore(),
          )
          .add(capture);

      return docRef.id;
    } catch (e) {
      print('Error creating capture: $e');
      throw Exception('Failed to create capture.');
    }
  }

  Future<void> updateCapture(String captureId, CaptureModel capture) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(captureId)
          .withConverter<CaptureModel>(
            fromFirestore: (snapshot, _) =>
                CaptureModel.fromFirestore(snapshot, null),
            toFirestore: (capture, _) => capture.toFirestore(),
          )
          .set(capture);
    } catch (e) {
      print('Error updating capture: $e');
      throw Exception('Failed to update capture.');
    }
  }

  Future<void> deleteCapture(String captureId) async {
    try {
      await _firestore.collection(_collectionPath).doc(captureId).delete();
    } catch (e) {
      print('Error deleting capture: $e');
      throw Exception('Failed to delete capture.');
    }
  }
}
