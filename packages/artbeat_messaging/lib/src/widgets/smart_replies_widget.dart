import 'package:flutter/material.dart';
import '../services/smart_replies_service.dart';

/// Widget that displays AI-powered smart reply suggestions
class SmartRepliesWidget extends StatefulWidget {
  final String chatId;
  final void Function(String) onReplySelected;
  final bool enabled;

  const SmartRepliesWidget({
    super.key,
    required this.chatId,
    required this.onReplySelected,
    this.enabled = true,
  });

  @override
  State<SmartRepliesWidget> createState() => _SmartRepliesWidgetState();
}

class _SmartRepliesWidgetState extends State<SmartRepliesWidget> {
  final SmartRepliesService _smartRepliesService = SmartRepliesService();
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _generateSuggestions();
    }
  }

  @override
  void didUpdateWidget(SmartRepliesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _generateSuggestions();
    }
  }

  Future<void> _generateSuggestions() async {
    if (_hasGenerated || !widget.enabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _smartRepliesService.generateSmartReplies(
        chatId: widget.chatId,
        maxSuggestions: 3,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _hasGenerated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasGenerated = true;
        });
      }
    }
  }

  void _onSuggestionTap(String suggestion) {
    widget.onReplySelected(suggestion);
    // Clear suggestions after selection
    setState(() {
      _suggestions.clear();
      _hasGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || (_suggestions.isEmpty && !_isLoading)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Smart replies',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestions.map((suggestion) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _onSuggestionTap(suggestion),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
