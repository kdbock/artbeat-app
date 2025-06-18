import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

class CaptureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'captures';

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

  // Add other capture-related service methods here, e.g.:
  // Future<String> createCapture(Map<String, dynamic> captureData) async { ... }
  // Future<void> updateCapture(String captureId, Map<String, dynamic> captureData) async { ... }
  // Future<void> deleteCapture(String captureId) async { ... }
}
