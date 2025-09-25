import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message_model.dart';
import '../theme/chat_theme.dart';

class VoiceMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _playAnimationController;
  late Animation<double> _playAnimation;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    debugPrint('VoiceMessageBubble: AudioPlayer initialized');

    // Animation for play button
    _playAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _playAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _playAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading =
              state == PlayerState.playing && _position == Duration.zero;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playAnimationController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      setState(() {
        _hasError = false;
      });

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Get voice URL from message metadata or content
        final voiceUrl = _getVoiceUrl();
        debugPrint(
          'VoiceMessageBubble: Attempting to play voice URL: $voiceUrl',
        );
        if (voiceUrl == null) {
          setState(() {
            _hasError = true;
          });
          return;
        }

        setState(() {
          _isLoading = true;
        });

        try {
          // Set the source and play
          await _audioPlayer.setSource(UrlSource(voiceUrl));

          if (_position == Duration.zero) {
            await _audioPlayer.resume();
          } else {
            await _audioPlayer.resume();
          }
          await _audioPlayer.setPlaybackRate(_playbackSpeed);
        } catch (playError) {
          debugPrint('Error playing voice message: $playError');
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _retryPlayback() {
    // Reset position and try playing again
    setState(() {
      _position = Duration.zero;
      _hasError = false;
    });
    _togglePlayback();
  }

  String? _getVoiceUrl() {
    // Try to get voice URL from metadata first, then from content
    return widget.message.metadata?['voiceUrl'] as String? ??
        (widget.message.content.startsWith('http')
            ? widget.message.content
            : null);
  }

  Duration _getVoiceDuration() {
    // Try to get duration from metadata, fallback to current duration
    final metadataDuration = widget.message.metadata?['duration'] as int?;
    if (metadataDuration != null) {
      return Duration(milliseconds: metadataDuration);
    }
    return _duration;
  }

  void _seekTo(double value) {
    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    );
    _audioPlayer.seek(position);
  }

  void _changePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    if (_isPlaying) {
      _audioPlayer.setPlaybackRate(_playbackSpeed);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final voiceDuration = _getVoiceDuration();
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280, minWidth: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: widget.isCurrentUser
              ? ChatTheme.primaryGradient
              : LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice message header
            Row(
              children: [
                Icon(
                  Icons.mic,
                  size: 16,
                  color: widget.isCurrentUser
                      ? Colors.white70
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Voice Message',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isCurrentUser
                        ? Colors.white70
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Main playback controls
            Row(
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: _hasError ? _retryPlayback : _togglePlayback,
                  child: AnimatedBuilder(
                    animation: _playAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasError
                              ? Colors.red.withValues(alpha: 0.1)
                              : widget.isCurrentUser
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.1),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _hasError
                                        ? Colors.red
                                        : widget.isCurrentUser
                                        ? Colors.white
                                        : Colors.blue,
                                  ),
                                ),
                              )
                            : Icon(
                                _hasError
                                    ? Icons.error
                                    : _isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: _hasError
                                    ? Colors.red
                                    : widget.isCurrentUser
                                    ? Colors.white
                                    : Colors.blue,
                                size: 24,
                              ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Waveform and progress
                Expanded(
                  child: Column(
                    children: [
                      // Waveform visualization
                      SizedBox(
                        height: 30,
                        child: CustomPaint(
                          painter: VoiceWaveformPainter(
                            progress: progress,
                            color: widget.isCurrentUser
                                ? Colors.white
                                : Colors.blue,
                            backgroundColor: widget.isCurrentUser
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                          size: const Size(double.infinity, 30),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Progress slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: _seekTo,
                          activeColor: widget.isCurrentUser
                              ? Colors.white
                              : Colors.blue,
                          inactiveColor: widget.isCurrentUser
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration display
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(voiceDuration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isCurrentUser
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),

                // Playback speed button
                GestureDetector(
                  onTap: _changePlaybackSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: widget.isCurrentUser
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.isCurrentUser
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceWaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  VoiceWaveformPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barCount = 25;
    final barWidth = size.width / barCount;
    final progressX = size.width * progress;

    // Generate waveform pattern
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;

      // Create varied heights for visual appeal
      double amplitude;
      if (i % 4 == 0) {
        amplitude = 0.8;
      } else if (i % 3 == 0) {
        amplitude = 0.6;
      } else if (i % 2 == 0) {
        amplitude = 0.4;
      } else {
        amplitude = 0.3;
      }

      final barHeight = amplitude * size.height * 0.7;

      // Choose color based on progress
      paint.color = x <= progressX ? color : backgroundColor;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
