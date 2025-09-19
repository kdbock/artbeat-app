import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Widget that displays turn-by-turn navigation instructions
class TurnByTurnNavigationWidget extends StatefulWidget {
  final ArtWalkNavigationService navigationService;
  final VoidCallback? onNextStep;
  final VoidCallback? onPreviousStep;
  final VoidCallback? onStopNavigation;
  final bool isCompact; // Whether to show compact version

  const TurnByTurnNavigationWidget({
    super.key,
    required this.navigationService,
    this.onNextStep,
    this.onPreviousStep,
    this.onStopNavigation,
    this.isCompact = false,
  });

  @override
  State<TurnByTurnNavigationWidget> createState() =>
      _TurnByTurnNavigationWidgetState();
}

class _TurnByTurnNavigationWidgetState extends State<TurnByTurnNavigationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  NavigationUpdate? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NavigationUpdate>(
      stream: widget.navigationService.navigationUpdates,
      builder: (context, snapshot) {
        debugPrint(
          '🧭 TurnByTurnWidget - Stream state: ${snapshot.connectionState}',
        );
        debugPrint('🧭 TurnByTurnWidget - Has data: ${snapshot.hasData}');
        debugPrint('🧭 TurnByTurnWidget - Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          debugPrint('🧭 TurnByTurnWidget - Error: ${snapshot.error}');
          return Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text('Navigation Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          debugPrint('🧭 TurnByTurnWidget - No data, showing loading...');
          return Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Loading navigation...'),
                  ],
                ),
              ),
            ),
          );
        }

        _lastUpdate = snapshot.data!;
        final update = _lastUpdate!;

        debugPrint('🧭 TurnByTurnWidget - Update type: ${update.type}');
        debugPrint(
          '🧭 TurnByTurnWidget - Current step: ${update.currentStep?.instruction}',
        );

        if (widget.isCompact) {
          return _buildCompactView(update);
        } else {
          return _buildFullView(update);
        }
      },
    );
  }

  Widget _buildCompactView(NavigationUpdate update) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Direction icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDirectionColor(update.currentStep?.maneuver),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    update.currentStep?.maneuverIcon ?? '⬆️',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Instruction text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      update.currentStep?.cleanInstruction ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (update.distanceToNextWaypoint != null)
                      Text(
                        'In ${update.distanceToNextWaypoint!.round()}m',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // Progress indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullView(NavigationUpdate update) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 12,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with route progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Turn-by-Turn Navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onStopNavigation,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route progress bar
              LinearProgressIndicator(
                value: update.routeProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress: ${(update.routeProgress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Current instruction
              Row(
                children: [
                  // Direction icon with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _getDirectionColor(
                              update.currentStep?.maneuver,
                            ),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: _getDirectionColor(
                                  update.currentStep?.maneuver,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              update.currentStep?.maneuverIcon ?? '⬆️',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),

                  // Instruction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.currentStep?.cleanInstruction ??
                              'Loading navigation...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (update.distanceToNextWaypoint != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'In ${update.distanceToNextWaypoint!.round()}m',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (update.currentStep != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                update.currentStep!.formattedDuration,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Off-route warning
              if (update.isOffRoute) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'re off the planned route. Follow the blue line to get back on track.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Next instruction preview
              if (update.currentSegment != null &&
                  update.currentStep != null &&
                  _hasNextStep(update)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getNextStep(update)?.maneuverIcon ?? '⬆️',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getNextStep(update)?.cleanInstruction ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Navigation controls
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.onPreviousStep,
                    icon: const Icon(Icons.skip_previous),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onNextStep,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDirectionColor(String? maneuver) {
    switch (maneuver?.toLowerCase()) {
      case 'turn-left':
      case 'turn-sharp-left':
      case 'turn-slight-left':
        return Colors.blue;
      case 'turn-right':
      case 'turn-sharp-right':
      case 'turn-slight-right':
        return Colors.green;
      case 'straight':
        return Colors.purple;
      case 'u-turn-left':
      case 'u-turn-right':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  bool _hasNextStep(NavigationUpdate update) {
    if (update.currentSegment == null || update.currentStep == null)
      return false;

    final segment = update.currentSegment!;
    final currentStepIndex = segment.steps.indexOf(update.currentStep!);

    return currentStepIndex >= 0 && currentStepIndex < segment.steps.length - 1;
  }

  NavigationStepModel? _getNextStep(NavigationUpdate update) {
    if (!_hasNextStep(update)) return null;

    final segment = update.currentSegment!;
    final currentStepIndex = segment.steps.indexOf(update.currentStep!);

    return segment.steps[currentStepIndex + 1];
  }
}
