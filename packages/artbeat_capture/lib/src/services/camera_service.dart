import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    // Upload to Firebase Storage
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId}';
    final Reference ref =
        _storage.ref().child('captures/$userId/$fileName.jpg');

    final UploadTask uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final TaskSnapshot snapshot = await uploadTask;
    final String imageUrl = await snapshot.ref.getDownloadURL();

    // Create thumbnail (you might want to implement thumbnail creation)
    final String thumbnailUrl = imageUrl; // For now, using same URL

    // Create capture model
    final capture = CaptureModel(
      id: '', // Will be set when saved to Firestore
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      textAnnotations: textAnnotations,
      createdAt: DateTime.now(),
      isProcessed: true,
    );

    // Save to Firestore
    final docRef = await _firestore.collection('captures').add(capture.toMap());
    return capture.copyWith(id: docRef.id);
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
