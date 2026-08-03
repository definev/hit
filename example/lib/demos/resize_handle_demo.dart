import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';

/// Window resize grip: tiny visual dots, large grab target.
class ResizeHandleDemo extends StatefulWidget {
  const ResizeHandleDemo({super.key});

  @override
  State<ResizeHandleDemo> createState() => _ResizeHandleDemoState();
}

class _ResizeHandleDemoState extends State<ResizeHandleDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  Offset beforeDelta = Offset.zero;
  Offset afterDelta = Offset.zero;

  static const _visual = Size(10, 10);
  static const _hit = Size(28, 28);

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Resize window handle',
      subtitle:
          'Corner grips are often 8–12px visually. HitLayer keeps layout tiny '
          'so the panel chrome stays crisp, while the grab zone is ~28px.',
      child: BeforeAfterSplit(
        before: _FakeWindow(
          label: 'drag corner',
          offset: beforeDelta,
          handle: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => setState(() {
              beforeDelta += d.delta;
              beforeTaps++;
            }),
            onTap: () => setState(() => beforeTaps++),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: _visual,
                  painter: _HitGhostPainter(
                    fill: HitExampleTheme.beforeFill,
                    stroke: HitExampleTheme.beforeStroke,
                  ),
                ),
                const _GripDots(size: _visual),
              ],
            ),
          ),
        ),
        after: HitScope(
          child: _FakeWindow(
            label: 'drag corner',
            offset: afterDelta,
            handle: HitLayer(
              alignment: Alignment.bottomRight,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => setState(() {
                  afterDelta += d.delta;
                  afterTaps++;
                }),
                onTap: () => setState(() => afterTaps++),
                child: SizedBox(
                  width: _hit.width,
                  height: _hit.height,
                  child: CustomPaint(
                    painter: _HitGhostPainter(
                      fill: HitExampleTheme.hitFill,
                      stroke: HitExampleTheme.hitStroke,
                    ),
                  ),
                ),
              ),
              paintChild: const IgnorePointer(child: _GripDots(size: _visual)),
            ),
          ),
        ),
        footer: TapStatsBar(
          beforeTaps: beforeTaps,
          afterTaps: afterTaps,
          hint: 'Drag or tap the corner grip. Green dashed box = expanded hit.',
        ),
      ),
    );
  }
}

class _FakeWindow extends StatelessWidget {
  const _FakeWindow({
    required this.handle,
    required this.offset,
    required this.label,
  });

  final Widget handle;
  final Offset offset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset.dx.clamp(-40, 40), offset.dy.clamp(-40, 40)),
      child: Container(
        width: 200,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HitExampleTheme.mist),
          boxShadow: [
            BoxShadow(
              color: HitExampleTheme.ink.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _traffic(const Color(0xFFE26D5A)),
                      const SizedBox(width: 6),
                      _traffic(const Color(0xFFE9C46A)),
                      const SizedBox(width: 6),
                      _traffic(const Color(0xFF2A9D8F)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: HitExampleTheme.ink.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(right: 6, bottom: 6, child: handle),
          ],
        ),
      ),
    );
  }

  Widget _traffic(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GripDots extends StatelessWidget {
  const _GripDots({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(painter: _GripPainter()),
    );
  }
}

class _GripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HitExampleTheme.ink.withValues(alpha: 0.45);
    const r = 1.2;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if (row + col < 2) continue;
        canvas.drawCircle(
          Offset(
            size.width * (0.2 + col * 0.3),
            size.height * (0.2 + row * 0.3),
          ),
          r,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
