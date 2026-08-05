part of '../main.dart';

class _HitGhost extends StatelessWidget {
  const _HitGhost({this.circular = false});

  final bool circular;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HitGhostPainter(circular: circular));
  }
}

class _HitGhostPainter extends CustomPainter {
  _HitGhostPainter({required this.circular});

  final bool circular;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    if (circular) {
      final double radius = size.shortestSide / 2;
      paintHitAreaDebugOverlay(canvas, rect, radius: radius);
    } else {
      paintHitAreaDebugOverlay(canvas, rect);
    }
  }

  @override
  bool shouldRepaint(covariant _HitGhostPainter oldDelegate) =>
      oldDelegate.circular != circular;
}
