import 'dart:io';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../models/capture_model.dart';

class CameraService {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // Initialize camera
  Future<void> initializeCamera() async {
    if (_isInitialized) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException(
          'No cameras found', 'No cameras are available on this device');
    }

    // Use first camera by default
    await _initController(_cameras[0]);
    _isInitialized = true;
  }

  // Initialize camera controller
  Future<void> _initController(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } on CameraException catch (e) {
      _isInitialized = false;
      throw CameraException(e.code, e.description);
    }
  }

  // Take picture and process it
  Future<CaptureModel> takePicture(String userId) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    // Verify user authentication first
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.uid != userId) {
      throw Exception('User must be logged in to capture images');
    }

    try {
      // Take picture
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      // Process image
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      final List<String> textAnnotations = recognizedText.blocks
          .map((block) => block.text)
          .where((text) => text.isNotEmpty)
          .toList();

      // Ensure App Check token is valid
      final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
      if (appCheckToken == null) {
        throw Exception('Failed to get App Check token');
      }

      // Upload to Firebase Storage with retry
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final Reference ref =
          _storage.ref().child('capture_images/$userId/$fileName.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'appCheckToken': appCheckToken,
        },
      );

      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      // Get location data
      Position? position = await _getLocation();

      // Create capture model
      final capture = CaptureModel(
        id: '', // Will be set when saved to Firestore
        userId: userId,
        imageUrl: imageUrl,
        thumbnailUrl: imageUrl, // For now, using same URL
        textAnnotations: textAnnotations,
        createdAt: DateTime.now(),
        isProcessed: true,
        location: position != null
            ? GeoPoint(position.latitude, position.longitude)
            : null,
        tags: ['captured'],
      );

      // Save to Firestore with proper authentication
      try {
        final docRef = await _firestore.collection('captures').add({
          ...capture.toMap(),
          'userId': userId, // Ensure userId is set for Firestore rules
          'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        });
        return capture.copyWith(id: docRef.id);
      } catch (e) {
        // Clean up the uploaded image if Firestore save fails
        await ref.delete();
        throw Exception('Failed to save capture metadata: $e');
      }
    } catch (e) {
      throw Exception('Failed to process and save capture: $e');
    }
  }

  // Get location using Geolocator
  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    final currentIndex = _cameras.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await _controller?.dispose();
    await _initController(_cameras[nextIndex]);
  }

  // Clean up resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _textRecognizer.close();
    _isInitialized = false;
  }
}
