import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'messaging_permission_service.dart';

enum RecordingState { idle, recording, paused, stopped }

enum PermissionResult { granted, denied, permanentlyDenied, restricted }

class VoiceRecordingService extends ChangeNotifier {
  static final Logger _logger = Logger('VoiceRecordingService');

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  RecordingState _recordingState = RecordingState.idle;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  final List<double> _waveformData = [];
  Timer? _recordingTimer;
  StreamSubscription<RecordingDisposition>? _recorderSubscription;

  // Getters
  RecordingState get recordingState => _recordingState;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  List<double> get waveformData => List.unmodifiable(_waveformData);
  bool get isRecording => _recordingState == RecordingState.recording;
  bool get isPaused => _recordingState == RecordingState.paused;
  bool get hasRecording =>
      _currentRecordingPath != null &&
      File(_currentRecordingPath!).existsSync();

  // Initialize the service
  Future<void> initialize() async {
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      // Configure audio session for recording
      await _recorder!.openRecorder();
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      await _player!.openPlayer();

      _logger.info('Voice recording service initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize voice recording service: $e');
      rethrow;
    }
  }

  // Check microphone permission (streamlined)
  Future<bool> _checkPermissions() async {
    return MessagingPermissionService().hasMicrophonePermission();
  }

  // Simplified permission check - no requests since app handles it at startup
  Future<PermissionResult> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      _logger.info('Current microphone permission status: $status');

      if (status.isGranted || status.isLimited) {
        return PermissionResult.granted;
      } else if (status.isPermanentlyDenied) {
        _logger.warning('Microphone permission permanently denied');
        return PermissionResult.permanentlyDenied;
      } else if (status.isRestricted) {
        _logger.warning('Microphone permission restricted');
        return PermissionResult.restricted;
      } else {
        _logger.warning('Microphone permission denied');
        return PermissionResult.denied;
      }
    } catch (e) {
      _logger.severe('Error checking microphone permissions: $e');
      return PermissionResult.denied;
    }
  }

  // Show message to user about opening Settings for permission
  void _showPermissionDeniedMessage() {
    // This method can be called by the UI to show an appropriate dialog
    // For now, we'll just log the message
    _logger.warning(
      'Microphone permission is required for voice recording. '
      'Please go to Settings > ARTbeat > Microphone and enable access.',
    );
    _logger.info(
      'To enable microphone access:\n'
      '1. Open Settings app\n'
      '2. Find and tap "ARTbeat"\n'
      '3. Tap "Microphone"\n'
      '4. Enable microphone access\n'
      '5. Return to ARTbeat and try recording again',
    );
  }

  // Method to explicitly request microphone permission
  Future<PermissionResult> requestMicrophonePermission() async {
    try {
      _logger.info('Explicitly requesting microphone permission...');
      final result = await Permission.microphone.request();
      _logger.info('Explicit permission request result: $result');
      _logger.info(
        'Result details: isDenied=${result.isDenied}, isGranted=${result.isGranted}, isPermanentlyDenied=${result.isPermanentlyDenied}, isRestricted=${result.isRestricted}, isLimited=${result.isLimited}',
      );

      if (result.isGranted || result.isLimited) {
        return PermissionResult.granted;
      } else if (result.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else if (result.isRestricted) {
        return PermissionResult.restricted;
      } else {
        return PermissionResult.denied;
      }
    } catch (e) {
      _logger.severe('Error requesting microphone permission: $e');
      return PermissionResult.denied;
    }
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      _logger.info('VoiceRecordingService.startRecording() called');
      _logger.info('Current state: $_recordingState');

      if (_recordingState != RecordingState.idle) {
        _logger.warning(
          'Cannot start recording: current state is $_recordingState',
        );
        return false;
      }

      // Ensure service is initialized
      if (_recorder == null || _player == null) {
        _logger.warning('Voice recording service not initialized');
        _logger.info(
          'Voice recording service not initialized, reinitializing...',
        );
        await initialize();
      }

      // Double-check recorder state
      _logger.info('Recorder state: ${_recorder?.isRecording}');

      // Check permissions
      _logger.info('Checking permissions...');
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _logger.warning('Microphone permission denied');
        return false;
      }
      _logger.info('Permissions granted');

      // Generate unique file path
      final directory = await getTemporaryDirectory();
      final fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentRecordingPath = '${directory.path}/$fileName';
      _logger.info('Recording to: $_currentRecordingPath');

      // Start recording
      _logger.info('Starting flutter_sound recorder...');
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );
      _logger.info('Flutter_sound recorder started successfully');

      _recordingState = RecordingState.recording;
      _recordingDuration = Duration.zero;
      _waveformData.clear();

      // Start duration timer
      _startRecordingTimer();

      // Start waveform monitoring
      _startWaveformMonitoring();

      notifyListeners();
      _logger.info('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      _logger.severe('Failed to start recording: $e');
      _recordingState = RecordingState.idle;
      notifyListeners();
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      if (_recordingState != RecordingState.recording &&
          _recordingState != RecordingState.paused) {
        _logger.warning(
          'Cannot stop recording: current state is $_recordingState',
        );
        return null;
      }

      // Check if recorder is initialized
      if (_recorder == null) {
        _logger.warning('Recorder not initialized');
        return null;
      }

      await _recorder!.stopRecorder();
      _stopRecordingTimer();
      _stopWaveformMonitoring();

      _recordingState = RecordingState.stopped;
      notifyListeners();

      final recordingPath = _currentRecordingPath;
      _logger.info(
        'Recording stopped: $recordingPath, duration: $_recordingDuration',
      );

      return recordingPath;
    } catch (e) {
      _logger.severe('Failed to stop recording: $e');
      return null;
    }
  }

  // Pause recording
  Future<bool> pauseRecording() async {
    try {
      if (_recordingState != RecordingState.recording) {
        return false;
      }

      if (_recorder == null) {
        _logger.warning('Recorder not initialized');
        return false;
      }

      await _recorder!.pauseRecorder();
      _recordingState = RecordingState.paused;
      _stopRecordingTimer();

      notifyListeners();
      _logger.info('Recording paused');
      return true;
    } catch (e) {
      _logger.severe('Failed to pause recording: $e');
      return false;
    }
  }

  // Resume recording
  Future<bool> resumeRecording() async {
    try {
      if (_recordingState != RecordingState.paused) {
        return false;
      }

      if (_recorder == null) {
        _logger.warning('Recorder not initialized');
        return false;
      }

      await _recorder!.resumeRecorder();
      _recordingState = RecordingState.recording;
      _startRecordingTimer();

      notifyListeners();
      _logger.info('Recording resumed');
      return true;
    } catch (e) {
      _logger.severe('Failed to resume recording: $e');
      return false;
    }
  }

  // Cancel recording and delete file
  Future<void> cancelRecording() async {
    try {
      if (_recordingState == RecordingState.recording ||
          _recordingState == RecordingState.paused) {
        await _recorder!.stopRecorder();
      }

      _stopRecordingTimer();
      _stopWaveformMonitoring();

      // Delete the recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.info('Recording file deleted: $_currentRecordingPath');
        }
      }

      _resetRecordingState();
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to cancel recording: $e');
    }
  }

  // Play recorded audio
  Future<bool> playRecording() async {
    try {
      if (_currentRecordingPath == null ||
          !File(_currentRecordingPath!).existsSync()) {
        _logger.warning('No recording file to play');
        return false;
      }

      if (_player == null) {
        _logger.warning('Player not initialized');
        await initialize();
      }

      await _player!.startPlayer(
        fromURI: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _logger.info('Playing recording: $_currentRecordingPath');
      return true;
    } catch (e) {
      _logger.severe('Failed to play recording: $e');
      return false;
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      if (_player == null) {
        _logger.warning('Player not initialized');
        return;
      }

      await _player!.stopPlayer();
      _logger.info('Playback stopped');
    } catch (e) {
      _logger.severe('Failed to stop playback: $e');
    }
  }

  // Get recording file size
  Future<int?> getRecordingSize() async {
    try {
      if (_currentRecordingPath == null) return null;

      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      _logger.severe('Failed to get recording size: $e');
      return null;
    }
  }

  // Private methods
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _recordingDuration = Duration(
        milliseconds: _recordingDuration.inMilliseconds + 100,
      );
      notifyListeners();
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _startWaveformMonitoring() {
    // Subscribe to recorder stream for waveform data
    _recorderSubscription = _recorder!.onProgress?.listen((
      RecordingDisposition event,
    ) {
      if (event.decibels != null) {
        // Convert decibels to normalized amplitude (0.0 to 1.0)
        final amplitude =
            (event.decibels! + 60) / 60; // Normalize -60dB to 0dB range
        final normalizedAmplitude = amplitude.clamp(0.0, 1.0);

        _waveformData.add(normalizedAmplitude);

        // Keep only last 100 samples for performance
        if (_waveformData.length > 100) {
          _waveformData.removeAt(0);
        }

        notifyListeners();
      }
    });
  }

  void _stopWaveformMonitoring() {
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
  }

  void _resetRecordingState() {
    _recordingState = RecordingState.idle;
    _recordingDuration = Duration.zero;
    _currentRecordingPath = null;
    _waveformData.clear();
  }

  // Open app settings for permission management
  Future<bool> openPermissionSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      _logger.severe('Failed to open app settings: $e');
      return false;
    }
  }

  // Check if microphone permission is available
  Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return Permission.microphone.status;
  }

  // Cleanup
  @override
  void dispose() {
    _stopRecordingTimer();
    _stopWaveformMonitoring();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }
}
