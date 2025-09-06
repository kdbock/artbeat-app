import 'package:flutter/material.dart';
import '../models/message_reaction_model.dart';

/// Quick reaction picker that appears when long-pressing a message
class QuickReactionPicker extends StatelessWidget {
  final VoidCallback onCancel;
  final void Function(String) onReactionSelected;
  final Offset? position;

  const QuickReactionPicker({
    super.key,
    required this.onCancel,
    required this.onReactionSelected,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onCancel,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.1),
          child: Stack(
            children: [
              if (position != null)
                Positioned(
                  left: _getPositionX(context),
                  top: _getPositionY(context),
                  child: _buildReactionContainer(),
                )
              else
                Center(child: _buildReactionContainer()),
            ],
          ),
        ),
      ),
    );
  }

  double _getPositionX(BuildContext context) {
    if (position == null) return 0;

    final screenWidth = MediaQuery.of(context).size.width;
    const containerWidth = 300.0; // Approximate container width

    double x = position!.dx - (containerWidth / 2);

    // Ensure the container stays within screen bounds
    if (x < 16) {
      x = 16;
    } else if (x + containerWidth > screenWidth - 16) {
      x = screenWidth - containerWidth - 16;
    }

    return x;
  }

  double _getPositionY(BuildContext context) {
    if (position == null) return 0;

    final screenHeight = MediaQuery.of(context).size.height;
    const containerHeight = 80.0;

    double y = position!.dy - containerHeight - 20;

    // If there's not enough space above, show below
    if (y < 50) {
      y = position!.dy + 20;
    }

    // Ensure it stays within screen bounds
    if (y + containerHeight > screenHeight - 50) {
      y = screenHeight - containerHeight - 50;
    }

    return y;
  }

  Widget _buildReactionContainer() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Most common reactions
                ...ReactionTypes.quickReactions.map((reactionType) {
                  final emoji = ReactionTypes.getEmoji(reactionType);
                  return _buildReactionButton(emoji, reactionType);
                }),

                const SizedBox(width: 8),

                // More reactions button
                _buildMoreReactionsButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(String emoji, String reactionType) {
    return GestureDetector(
      onTap: () => onReactionSelected(reactionType),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
    );
  }

  Widget _buildMoreReactionsButton() {
    return GestureDetector(
      onTap: () {
        onCancel();
        // TODO: Show full reaction picker
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.add, size: 20, color: Colors.grey),
      ),
    );
  }
}

/// Reaction animation overlay for visual feedback
class ReactionAnimationOverlay extends StatefulWidget {
  final String emoji;
  final Offset startPosition;
  final VoidCallback onComplete;

  const ReactionAnimationOverlay({
    super.key,
    required this.emoji,
    required this.startPosition,
    required this.onComplete,
  });

  @override
  State<ReactionAnimationOverlay> createState() =>
      _ReactionAnimationOverlayState();
}

class _ReactionAnimationOverlayState extends State<ReactionAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _moveController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _moveAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _moveAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -50),
    ).animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOut));

    _startAnimation();
  }

  void _startAnimation() async {
    await _scaleController.forward();
    await _moveController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.startPosition.dx - 15,
      top: widget.startPosition.dy - 15,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _moveController]),
        builder: (context, child) {
          return Transform.translate(
            offset: _moveAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: 1.0 - _moveController.value,
                child: Text(widget.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
          );
        },
      ),
    );
  }
}
