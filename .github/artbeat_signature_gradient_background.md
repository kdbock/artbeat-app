ARTbeat Signature Gradient Background
Color Palette:
Primary Purple: ArtbeatColors.primaryPurple
Primary Green: ArtbeatColors.primaryGreen
Blue Accent: Color(0xFF4A90E2)
White: Colors.white
Gradient Configuration:
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.white,
    ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
    const Color(0xFF4A90E2).withValues(alpha: 0.2), // Blue
    Colors.white.withValues(alpha: 0.95),
    ArtbeatColors.primaryGreen.withValues(alpha: 0.12),
    Colors.white,
  ],
  stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
)
Shadow Effects:
boxShadow: [
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.8),
    blurRadius: 4,
    offset: const Offset(-1, -1),
  ),
  BoxShadow(
    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
    blurRadius: 8,
    offset: const Offset(1, 1),
  ),
]
Key Features:
Diagonal flow: Top-left to bottom-right
6 color stops for smooth transitions
Low opacity (0.12-0.2) for subtle effect
White base for brightness
Subtle shadows for depth
Purple → Blue → Green color progression
Usage Note:
This creates a bright, artistic gradient with your app's signature colors that works perfectly for headers, navigation bars, and background elements. The low alpha values ensure text remains readable while adding visual appeal.