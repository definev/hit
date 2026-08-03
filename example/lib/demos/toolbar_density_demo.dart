import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Packed toolbar icons — hits can overlap neighbors without layout padding.
class ToolbarDensityDemo extends StatefulWidget {
  const ToolbarDensityDemo({super.key});

  @override
  State<ToolbarDensityDemo> createState() => _ToolbarDensityDemoState();
}

class _ToolbarDensityDemoState extends State<ToolbarDensityDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  String last = '—';

  static const tools = <(IconData, String)>[
    (Icons.undo, 'undo'),
    (Icons.redo, 'redo'),
    (Icons.crop, 'crop'),
    (Icons.rotate_right, 'rotate'),
    (Icons.text_fields, 'type'),
    (Icons.palette_outlined, 'color'),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Dense toolbar',
      subtitle:
          'Icons sit 4px apart visually. Before requires precise taps. After '
          'gives each a 40×40 hit that overflows — HitScope delivers corner taps.',
      child: BeforeAfterSplit(
        before: _Toolbar(
          children: [
            for (final tool in tools)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TightHitTarget(
                  onTap: () => setState(() {
                    beforeTaps++;
                    last = 'before · ${tool.$2}';
                  }),
                  child: Icon(tool.$1, size: 18),
                ),
              ),
          ],
        ),
        after: HitScope(
          child: _Toolbar(
            children: [
              for (final tool in tools)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ExpandedHitTarget(
                    onTap: () => setState(() {
                      afterTaps++;
                      last = 'after · ${tool.$2}';
                    }),
                    hitSize: const Size(40, 40),
                    paintChild: Icon(tool.$1, size: 18),
                  ),
                ),
            ],
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Last tool: $last',
                style: TextStyle(
                  fontSize: 12,
                  color: HitExampleTheme.ink.withValues(alpha: 0.55),
                ),
              ),
            ),
            TapStatsBar(
              beforeTaps: beforeTaps,
              afterTaps: afterTaps,
              hint: 'Tap between icons — After is far more forgiving.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HitExampleTheme.mist),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
