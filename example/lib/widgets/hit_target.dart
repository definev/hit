import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';

/// Wraps a small visual in a larger hit target without growing layout.
class ExpandedHitTarget extends StatelessWidget {
  const ExpandedHitTarget({
    super.key,
    required this.onTap,
    required this.paintChild,
    this.hitSize = const Size(48, 48),
    this.alignment = Alignment.center,
    this.debugShowHitArea = true,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final VoidCallback onTap;
  final Widget paintChild;
  final Size hitSize;
  final AlignmentGeometry alignment;
  final bool debugShowHitArea;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return HitLayer(
      alignment: alignment,
      behavior: behavior,
      hitChild: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: hitSize.width,
          height: hitSize.height,
          child: debugShowHitArea
              ? CustomPaint(
                  painter: _HitGhostPainter(
                    fill: HitExampleTheme.hitFill,
                    stroke: HitExampleTheme.hitStroke,
                  ),
                )
              : null,
        ),
      ),
      paintChild: IgnorePointer(child: paintChild),
    );
  }
}

/// Same visual, but hit area equals paint size (the “before” case).
class TightHitTarget extends StatelessWidget {
  const TightHitTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.debugShowHitArea = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool debugShowHitArea;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (debugShowHitArea)
            Positioned.fill(
              child: CustomPaint(
                painter: _HitGhostPainter(
                  fill: HitExampleTheme.beforeFill,
                  stroke: HitExampleTheme.beforeStroke,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _HitGhostPainter extends CustomPainter {
  _HitGhostPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = fill,
    );
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 3.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(0.6), const Radius.circular(4)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HitGhostPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.stroke != stroke;
  }
}
