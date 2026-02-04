// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Encryption Pattern Background - Reusable background pattern widget
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// A container with an encryption grid pattern background.
class EncryptionPatternBackground extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? patternColor;
  final Widget? child;

  const EncryptionPatternBackground({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 24,
    this.backgroundColor,
    this.patternColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        backgroundColor ??
        theme.colorScheme.primaryContainer.withValues(alpha: 0.2);
    final gridColor =
        patternColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _EncryptionPatternPainter(color: gridColor),
            child: SizedBox(width: width, height: height),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Custom painter for encryption pattern background.
class _EncryptionPatternPainter extends CustomPainter {
  final Color color;

  _EncryptionPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw a grid pattern representing encrypted data
    final spacing = 16.0;

    // Calculate offset to center the grid (so edges don't show on top-left)
    final offsetX = (size.width % spacing) / 2;
    final offsetY = (size.height % spacing) / 2;

    // Vertical lines
    for (double x = offsetX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = offsetY; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_EncryptionPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
