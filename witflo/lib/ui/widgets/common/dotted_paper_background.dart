// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Dotted Paper Background - Subtle dotted pattern for note editor
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// A dotted paper background widget that gives a notebook paper feel.
class DottedPaperBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? dotColor;
  final double dotSize;
  final double dotSpacing;

  const DottedPaperBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.dotColor,
    this.dotSize = 1.5,
    this.dotSpacing = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final dots = dotColor ?? theme.dividerColor.withValues(alpha: 0.15);

    return Container(
      color: bgColor,
      child: CustomPaint(
        painter: _DottedPaperPainter(
          dotColor: dots,
          dotSize: dotSize,
          dotSpacing: dotSpacing,
        ),
        child: child,
      ),
    );
  }
}

/// Custom painter for dotted paper pattern.
class _DottedPaperPainter extends CustomPainter {
  final Color dotColor;
  final double dotSize;
  final double dotSpacing;

  _DottedPaperPainter({
    required this.dotColor,
    required this.dotSize,
    required this.dotSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Calculate offset to center the grid
    final offsetX = (size.width % dotSpacing) / 2;
    final offsetY = (size.height % dotSpacing) / 2;

    // Draw dots in a grid pattern
    for (double x = offsetX; x < size.width; x += dotSpacing) {
      for (double y = offsetY; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPaperPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.dotSize != dotSize ||
      oldDelegate.dotSpacing != dotSpacing;
}
