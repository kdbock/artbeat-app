import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capture_model.dart';

class CaptureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CaptureModel> saveCapture({
    required String imageUrl,
    required String title,
    required String description,
    required String artistId,
    GeoPoint? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to save captures');
    }

    final captureData = {
      'userId': user.uid,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'artistId': artistId,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('captures').add(captureData);

    final snapshot = await docRef.get();
    return CaptureModel.fromFirestore(
      snapshot,
      null,
    );
  }
}
