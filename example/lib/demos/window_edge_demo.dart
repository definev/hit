import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';

const _kVisualThickness = 2.0;
const _kHitThickness = 12.0;

/// Thin visual edges with thick hit strips — classic desktop window chrome.
class WindowEdgeDemo extends StatefulWidget {
  const WindowEdgeDemo({super.key});

  @override
  State<WindowEdgeDemo> createState() => _WindowEdgeDemoState();
}

class _WindowEdgeDemoState extends State<WindowEdgeDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  String lastEdge = '—';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Window edge resize',
      subtitle:
          'Hairline borders look right; 12px hit strips make resize reliable. '
          'alignment pins paint to the outer edge of each strip.',
      child: BeforeAfterSplit(
        before: _PanelFrame(
          showExpandedHit: false,
          onEdge: (edge) => setState(() {
            beforeTaps++;
            lastEdge = 'before · $edge';
          }),
        ),
        after: HitScope(
          child: _PanelFrame(
            showExpandedHit: true,
            onEdge: (edge) => setState(() {
              afterTaps++;
              lastEdge = 'after · $edge';
            }),
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Last hit: $lastEdge',
                style: TextStyle(
                  fontSize: 12,
                  color: HitExampleTheme.ink.withValues(alpha: 0.55),
                ),
              ),
            ),
            TapStatsBar(
              beforeTaps: beforeTaps,
              afterTaps: afterTaps,
              hint: 'Aim just outside the border — only After registers.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.onEdge, required this.showExpandedHit});

  final ValueChanged<String> onEdge;
  final bool showExpandedHit;

  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: HitExampleTheme.ink.withValues(alpha: 0.2),
                  width: _kVisualThickness,
                ),
              ),
              child: Center(
                child: Text(
                  showExpandedHit ? 'hit edges' : 'visual only',
                  style: TextStyle(
                    fontSize: 12,
                    color: HitExampleTheme.ink.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          ..._edges(),
        ],
      ),
    );
  }

  List<Widget> _edges() {
    if (!showExpandedHit) {
      return [
        _tightEdge(Alignment.topCenter, 'top', horizontal: true),
        _tightEdge(Alignment.bottomCenter, 'bottom', horizontal: true),
        _tightEdge(Alignment.centerLeft, 'left', horizontal: false),
        _tightEdge(Alignment.centerRight, 'right', horizontal: false),
      ];
    }

    return [
      _expandedEdge(
        alignment: Alignment.topCenter,
        label: 'top',
        hit: const Size(180, _kHitThickness),
        paint: const Size(180, _kVisualThickness),
      ),
      _expandedEdge(
        alignment: Alignment.bottomCenter,
        label: 'bottom',
        hit: const Size(180, _kHitThickness),
        paint: const Size(180, _kVisualThickness),
      ),
      _expandedEdge(
        alignment: Alignment.centerLeft,
        label: 'left',
        hit: const Size(_kHitThickness, 180),
        paint: const Size(_kVisualThickness, 180),
      ),
      _expandedEdge(
        alignment: Alignment.centerRight,
        label: 'right',
        hit: const Size(_kHitThickness, 180),
        paint: const Size(_kVisualThickness, 180),
      ),
    ];
  }

  Widget _tightEdge(Alignment align, String label, {required bool horizontal}) {
    return Align(
      alignment: align,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onEdge(label),
        child: Container(
          width: horizontal ? 180 : _kVisualThickness,
          height: horizontal ? _kVisualThickness : 180,
          color: HitExampleTheme.beforeFill,
        ),
      ),
    );
  }

  Widget _expandedEdge({
    required Alignment alignment,
    required String label,
    required Size hit,
    required Size paint,
  }) {
    return Align(
      alignment: alignment,
      child: HitLayer(
        alignment: alignment,
        behavior: HitTestBehavior.deferToChild,
        hitChild: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onEdge(label),
          child: SizedBox(
            width: hit.width,
            height: hit.height,
            child: CustomPaint(painter: _EdgeHitPainter()),
          ),
        ),
        paintChild: IgnorePointer(
          child: SizedBox(width: paint.width, height: paint.height),
        ),
      ),
    );
  }
}

class _EdgeHitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = HitExampleTheme.hitFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
