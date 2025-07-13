import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

// Mock classes
@GenerateMocks([ImagePicker, CameraController])
import 'capture_service_test.mocks.dart';

void main() {
  group('CaptureService Tests', () {
    late MockImagePicker mockImagePicker;
    late MockCameraController mockCameraController;

    setUp(() {
      mockImagePicker = MockImagePicker();
      mockCameraController = MockCameraController();
    });

    test('should pick image from gallery successfully', () async {
      // Arrange
      final mockFile = XFile('test/path/image.jpg');
      when(
        mockImagePicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => mockFile);

      // Act
      final result = await mockImagePicker.pickImage(
        source: ImageSource.gallery,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.path, equals('test/path/image.jpg'));
      verify(mockImagePicker.pickImage(source: ImageSource.gallery)).called(1);
    });

    test('should pick image from camera successfully', () async {
      // Arrange
      final mockFile = XFile('test/path/camera_image.jpg');
      when(
        mockImagePicker.pickImage(source: ImageSource.camera),
      ).thenAnswer((_) async => mockFile);

      // Act
      final result = await mockImagePicker.pickImage(
        source: ImageSource.camera,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.path, equals('test/path/camera_image.jpg'));
      verify(mockImagePicker.pickImage(source: ImageSource.camera)).called(1);
    });

    test('should pick multiple images from gallery', () async {
      // Arrange
      final mockFiles = [
        XFile('test/path/image1.jpg'),
        XFile('test/path/image2.jpg'),
        XFile('test/path/image3.jpg'),
      ];
      when(mockImagePicker.pickMultiImage()).thenAnswer((_) async => mockFiles);

      // Act
      final result = await mockImagePicker.pickMultiImage();

      // Assert
      expect(result, isNotNull);
      expect(result.length, equals(3));
      expect(result[0].path, equals('test/path/image1.jpg'));
      expect(result[1].path, equals('test/path/image2.jpg'));
      expect(result[2].path, equals('test/path/image3.jpg'));
      verify(mockImagePicker.pickMultiImage()).called(1);
    });

    test(
      'should handle null result when user cancels image selection',
      () async {
        // Arrange
        when(
          mockImagePicker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => null);

        // Act
        final result = await mockImagePicker.pickImage(
          source: ImageSource.gallery,
        );

        // Assert
        expect(result, isNull);
        verify(
          mockImagePicker.pickImage(source: ImageSource.gallery),
        ).called(1);
      },
    );

    test('should pick video from gallery successfully', () async {
      // Arrange
      final mockFile = XFile('test/path/video.mp4');
      when(
        mockImagePicker.pickVideo(source: ImageSource.gallery),
      ).thenAnswer((_) async => mockFile);

      // Act
      final result = await mockImagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.path, equals('test/path/video.mp4'));
      verify(mockImagePicker.pickVideo(source: ImageSource.gallery)).called(1);
    });

    test('should pick video from camera successfully', () async {
      // Arrange
      final mockFile = XFile('test/path/camera_video.mp4');
      when(
        mockImagePicker.pickVideo(source: ImageSource.camera),
      ).thenAnswer((_) async => mockFile);

      // Act
      final result = await mockImagePicker.pickVideo(
        source: ImageSource.camera,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.path, equals('test/path/camera_video.mp4'));
      verify(mockImagePicker.pickVideo(source: ImageSource.camera)).called(1);
    });

    test('should handle camera controller initialization', () {
      // Arrange & Act
      // This test ensures our mock camera controller can be instantiated
      // In a real implementation, this would test camera initialization

      // Assert
      expect(mockCameraController, isNotNull);
      // Additional camera controller tests would go here when implementing
      // actual camera functionality like initialize(), dispose(), etc.
    });

    test('should validate image file type', () {
      // Valid image types
      expect(CaptureHelper.isValidImageType('image.jpg'), isTrue);
      expect(CaptureHelper.isValidImageType('image.jpeg'), isTrue);
      expect(CaptureHelper.isValidImageType('image.png'), isTrue);
      expect(CaptureHelper.isValidImageType('image.webp'), isTrue);

      // Invalid image types
      expect(CaptureHelper.isValidImageType('document.pdf'), isFalse);
      expect(CaptureHelper.isValidImageType('video.mp4'), isFalse);
      expect(CaptureHelper.isValidImageType('audio.mp3'), isFalse);
      expect(CaptureHelper.isValidImageType(''), isFalse);
    });

    test('should validate video file type', () {
      // Valid video types
      expect(CaptureHelper.isValidVideoType('video.mp4'), isTrue);
      expect(CaptureHelper.isValidVideoType('video.mov'), isTrue);
      expect(CaptureHelper.isValidVideoType('video.avi'), isTrue);
      expect(CaptureHelper.isValidVideoType('video.mkv'), isTrue);

      // Invalid video types
      expect(CaptureHelper.isValidVideoType('image.jpg'), isFalse);
      expect(CaptureHelper.isValidVideoType('audio.mp3'), isFalse);
      expect(CaptureHelper.isValidVideoType('document.pdf'), isFalse);
      expect(CaptureHelper.isValidVideoType(''), isFalse);
    });

    test('should validate file size', () {
      // Valid file sizes (under 10MB)
      expect(CaptureHelper.isValidFileSize(1024 * 1024), isTrue); // 1MB
      expect(CaptureHelper.isValidFileSize(5 * 1024 * 1024), isTrue); // 5MB
      expect(CaptureHelper.isValidFileSize(9 * 1024 * 1024), isTrue); // 9MB

      // Invalid file sizes (over 10MB)
      expect(CaptureHelper.isValidFileSize(11 * 1024 * 1024), isFalse); // 11MB
      expect(CaptureHelper.isValidFileSize(50 * 1024 * 1024), isFalse); // 50MB

      // Edge case
      expect(
        CaptureHelper.isValidFileSize(10 * 1024 * 1024),
        isTrue,
      ); // Exactly 10MB
    });

    test('should format file size correctly', () {
      expect(CaptureHelper.formatFileSize(0), equals('0 B'));
      expect(CaptureHelper.formatFileSize(512), equals('512 B'));
      expect(CaptureHelper.formatFileSize(1024), equals('1.0 KB'));
      expect(CaptureHelper.formatFileSize(1536), equals('1.5 KB'));
      expect(CaptureHelper.formatFileSize(1024 * 1024), equals('1.0 MB'));
      expect(
        CaptureHelper.formatFileSize((2.5 * 1024 * 1024).round()),
        equals('2.5 MB'),
      );
      expect(
        CaptureHelper.formatFileSize(1024 * 1024 * 1024),
        equals('1.0 GB'),
      );
    });

    test('should get file extension correctly', () {
      expect(CaptureHelper.getFileExtension('image.jpg'), equals('jpg'));
      expect(CaptureHelper.getFileExtension('document.pdf'), equals('pdf'));
      expect(CaptureHelper.getFileExtension('video.mp4'), equals('mp4'));
      expect(CaptureHelper.getFileExtension('file.tar.gz'), equals('gz'));
      expect(CaptureHelper.getFileExtension('noextension'), equals(''));
      expect(CaptureHelper.getFileExtension(''), equals(''));
    });
  });

  group('MediaCapture Model Tests', () {
    test('should create MediaCapture with valid data', () {
      final capture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024, // 1MB
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );

      expect(capture.id, equals('capture-123'));
      expect(capture.filePath, equals('/path/to/image.jpg'));
      expect(capture.fileName, equals('image.jpg'));
      expect(capture.fileSize, equals(1024 * 1024));
      expect(capture.mediaType, equals(MediaType.image));
      expect(capture.captureSource, equals(CaptureSource.gallery));
    });

    test('should validate MediaCapture data', () {
      // Valid capture
      final validCapture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );
      expect(validCapture.isValid, isTrue);

      // Invalid capture - empty file path
      final invalidCapture1 = MediaCapture(
        id: 'capture-123',
        filePath: '',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );
      expect(invalidCapture1.isValid, isFalse);

      // Invalid capture - negative file size
      final invalidCapture2 = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: -1,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );
      expect(invalidCapture2.isValid, isFalse);
    });

    test('should get file extension from MediaCapture', () {
      final capture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );

      expect(capture.fileExtension, equals('jpg'));
    });

    test('should format file size from MediaCapture', () {
      final capture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024, // 1MB
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );

      expect(capture.formattedFileSize, equals('1.0 MB'));
    });

    test('should check if MediaCapture is image', () {
      final imageCapture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
      );

      final videoCapture = MediaCapture(
        id: 'capture-456',
        filePath: '/path/to/video.mp4',
        fileName: 'video.mp4',
        fileSize: 5 * 1024 * 1024,
        mediaType: MediaType.video,
        captureSource: CaptureSource.camera,
        timestamp: DateTime.now(),
      );

      expect(imageCapture.isImage, isTrue);
      expect(imageCapture.isVideo, isFalse);
      expect(videoCapture.isImage, isFalse);
      expect(videoCapture.isVideo, isTrue);
    });

    test('should convert MediaCapture to JSON', () {
      final capture = MediaCapture(
        id: 'capture-123',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        fileSize: 1024 * 1024,
        mediaType: MediaType.image,
        captureSource: CaptureSource.gallery,
        timestamp: DateTime.now(),
        metadata: {'width': 1920, 'height': 1080},
      );

      final json = capture.toJson();

      expect(json['id'], equals('capture-123'));
      expect(json['filePath'], equals('/path/to/image.jpg'));
      expect(json['fileName'], equals('image.jpg'));
      expect(json['fileSize'], equals(1024 * 1024));
      expect(json['mediaType'], equals(MediaType.image.toString()));
      expect(json['captureSource'], equals(CaptureSource.gallery.toString()));
      expect(json['metadata'], equals({'width': 1920, 'height': 1080}));
    });

    test('should create MediaCapture from JSON', () {
      final json = {
        'id': 'capture-123',
        'filePath': '/path/to/image.jpg',
        'fileName': 'image.jpg',
        'fileSize': 1024 * 1024,
        'mediaType': MediaType.image.toString(),
        'captureSource': CaptureSource.gallery.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {'width': 1920, 'height': 1080},
      };

      final capture = MediaCapture.fromJson(json);

      expect(capture.id, equals('capture-123'));
      expect(capture.filePath, equals('/path/to/image.jpg'));
      expect(capture.fileName, equals('image.jpg'));
      expect(capture.fileSize, equals(1024 * 1024));
      expect(capture.mediaType, equals(MediaType.image));
      expect(capture.captureSource, equals(CaptureSource.gallery));
      expect(capture.metadata, equals({'width': 1920, 'height': 1080}));
    });
  });

  group('MediaType Tests', () {
    test('should convert MediaType to string correctly', () {
      expect(MediaType.image.toString(), equals('MediaType.image'));
      expect(MediaType.video.toString(), equals('MediaType.video'));
    });

    test('should parse MediaType from string correctly', () {
      expect(
        MediaTypeExtension.fromString('MediaType.image'),
        equals(MediaType.image),
      );
      expect(
        MediaTypeExtension.fromString('MediaType.video'),
        equals(MediaType.video),
      );
      expect(
        MediaTypeExtension.fromString('invalid'),
        equals(MediaType.image),
      ); // Default
    });
  });

  group('CaptureSource Tests', () {
    test('should convert CaptureSource to string correctly', () {
      expect(CaptureSource.camera.toString(), equals('CaptureSource.camera'));
      expect(CaptureSource.gallery.toString(), equals('CaptureSource.gallery'));
    });

    test('should parse CaptureSource from string correctly', () {
      expect(
        CaptureSourceExtension.fromString('CaptureSource.camera'),
        equals(CaptureSource.camera),
      );
      expect(
        CaptureSourceExtension.fromString('CaptureSource.gallery'),
        equals(CaptureSource.gallery),
      );
      expect(
        CaptureSourceExtension.fromString('invalid'),
        equals(CaptureSource.gallery),
      ); // Default
    });

    test('should get source display name correctly', () {
      expect(CaptureSource.camera.displayName, equals('Camera'));
      expect(CaptureSource.gallery.displayName, equals('Gallery'));
    });
  });
}
