import 'package:flutter/material.dart';
import '../models/studio_model.dart';
import '../services/firestore_service.dart';

class StudioController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  StudioController(this._firestoreService);

  List<StudioModel> _studios = [];
  List<StudioModel> get studios => _studios;

  Future<void> fetchStudios() async {
    try {
      _studios = await _firestoreService.getStudios();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching studios: $e');
    }
  }

  Future<void> createStudio(StudioModel studio) async {
    try {
      await _firestoreService.createStudio(studio);
      _studios.add(studio);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating studio: $e');
    }
  }

  Future<void> deleteStudio(String studioId) async {
    try {
      await _firestoreService.deleteStudio(studioId);
      _studios.removeWhere((studio) => studio.id == studioId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting studio: $e');
    }
  }
}
