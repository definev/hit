import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Classic: 24px icon / 48px hit — layout stays 24 so neighbors don’t shift.
class IconButtonDemo extends StatefulWidget {
  const IconButtonDemo({super.key});

  @override
  State<IconButtonDemo> createState() => _IconButtonDemoState();
}

class _IconButtonDemoState extends State<IconButtonDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;

  static const _iconSize = 24.0;
  static const _hitSize = Size(48, 48);

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Icon button',
      subtitle:
          'Paint is 24×24. After expands hit to 48×48 via HitLayer without '
          'pushing adjacent text — layout still measures paint size.',
      child: BeforeAfterSplit(
        before: _NeighborRow(
          control: TapFlash(
            trigger: beforeTaps,
            child: TightHitTarget(
              onTap: () => setState(() => beforeTaps++),
              child: const Icon(Icons.add, size: _iconSize),
            ),
          ),
        ),
        after: HitScope(
          child: _NeighborRow(
            control: TapFlash(
              trigger: afterTaps,
              child: ExpandedHitTarget(
                behavior: .translucent,
                onTap: () {
                  setState(() => afterTaps++);
                },
                hitSize: _hitSize,
                paintChild: const Icon(Icons.add, size: _iconSize),
              ),
            ),
          ),
        ),
        footer: TapStatsBar(beforeTaps: beforeTaps, afterTaps: afterTaps),
      ),
    );
  }
}

class _NeighborRow extends StatelessWidget {
  const _NeighborRow({required this.control});

  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HitExampleTheme.mist),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          control,
          const SizedBox(width: 8),
          Text(
            'New item',
            style: TextStyle(
              fontSize: 15,
              color: HitExampleTheme.ink.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
