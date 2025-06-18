import 'package:flutter/material.dart';
import '../theme/artbeat_components.dart';

class ArtbeatButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;

  const ArtbeatButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _getButtonStyle(),
      child: child,
    );
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case ButtonVariant.primary:
        return ArtbeatComponents.primaryButtonStyle;
      case ButtonVariant.secondary:
        return ArtbeatComponents.secondaryButtonStyle;
      case ButtonVariant.outlined:
        return ArtbeatComponents.outlinedButtonStyle;
    }
  }
}

enum ButtonVariant { primary, secondary, outlined }
