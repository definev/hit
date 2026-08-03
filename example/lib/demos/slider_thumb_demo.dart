import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';

/// Small polished thumb with a large scrubbing hit target.
class SliderThumbDemo extends StatefulWidget {
  const SliderThumbDemo({super.key});

  @override
  State<SliderThumbDemo> createState() => _SliderThumbDemoState();
}

class _SliderThumbDemoState extends State<SliderThumbDemo> {
  double beforeValue = 0.35;
  double afterValue = 0.65;
  int beforeTaps = 0;
  int afterTaps = 0;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Slider thumb',
      subtitle:
          'Thumb paints at 14px. After uses a 36×36 hit so scrubbing near the '
          'thumb still captures — layout width of the track is unchanged.',
      child: BeforeAfterSplit(
        before: _HitSlider(
          value: beforeValue,
          expandedHit: false,
          onChanged: (v) => setState(() {
            beforeValue = v;
            beforeTaps++;
          }),
        ),
        after: HitScope(
          child: _HitSlider(
            value: afterValue,
            expandedHit: true,
            onChanged: (v) => setState(() {
              afterValue = v;
              afterTaps++;
            }),
          ),
        ),
        footer: TapStatsBar(
          beforeTaps: beforeTaps,
          afterTaps: afterTaps,
          hint: 'Drag slightly above/below the thumb — After stays sticky.',
        ),
      ),
    );
  }
}

class _HitSlider extends StatelessWidget {
  const _HitSlider({
    required this.value,
    required this.onChanged,
    required this.expandedHit,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final bool expandedHit;

  static const trackWidth = 220.0;
  static const thumbVisual = 14.0;
  static const thumbHit = 36.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: trackWidth,
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackLeft = 0.0;
          final usable = trackWidth - thumbVisual;
          final thumbX = trackLeft + value * usable;

          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: HitExampleTheme.mist,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: HitExampleTheme.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbX,
                    child: expandedHit
                        ? HitLayer(
                            alignment: Alignment.center,
                            behavior: HitTestBehavior.deferToChild,
                            hitChild: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (d) {
                                final next = (value + d.delta.dx / usable)
                                    .clamp(0.0, 1.0);
                                onChanged(next);
                              },
                              onTap: () => onChanged(value),
                              child: SizedBox(
                                width: thumbHit,
                                height: thumbHit,
                                child: CustomPaint(painter: _ThumbHitPainter()),
                              ),
                            ),
                            paintChild: const IgnorePointer(
                              child: _ThumbVisual(size: thumbVisual),
                            ),
                          )
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (d) {
                              final next = (value + d.delta.dx / usable).clamp(
                                0.0,
                                1.0,
                              );
                              onChanged(next);
                            },
                            onTap: () => onChanged(value),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(thumbVisual, thumbVisual),
                                  painter: _ThumbHitPainter(
                                    fill: HitExampleTheme.beforeFill,
                                    stroke: HitExampleTheme.beforeStroke,
                                  ),
                                ),
                                const _ThumbVisual(size: thumbVisual),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              Text('Below'),
            ],
          );
        },
      ),
    );
  }
}

class _ThumbVisual extends StatelessWidget {
  const _ThumbVisual({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: HitExampleTheme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: HitExampleTheme.ink.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _ThumbHitPainter extends CustomPainter {
  _ThumbHitPainter({
    this.fill = HitExampleTheme.hitFill,
    this.stroke = HitExampleTheme.hitStroke,
  });

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(6)),
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbHitPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.stroke != stroke;
  }
}
