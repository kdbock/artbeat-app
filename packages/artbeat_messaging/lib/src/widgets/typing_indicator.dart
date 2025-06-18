import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicator({super.key, required this.typingUsers});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Circle(delay: index, controller: _controller),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(_getTypingText(), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers[0]} is typing...';
    }
    return '${widget.typingUsers.length} people are typing...';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Circle extends StatelessWidget {
  final int delay;
  final AnimationController controller;

  const Circle({super.key, required this.delay, required this.controller});

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay * 0.2, 1.0, curve: Curves.easeInOut),
    );

    return ScaleTransition(
      scale: animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
