import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Dense filter chips: tiny × with expanded hit that doesn’t inflate chip height.
class ChipDismissDemo extends StatefulWidget {
  const ChipDismissDemo({super.key});

  @override
  State<ChipDismissDemo> createState() => _ChipDismissDemoState();
}

class _ChipDismissDemoState extends State<ChipDismissDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;

  static const labels = ['Design', 'Motion', 'Tokens', 'A11y'];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Chip dismiss',
      subtitle:
          'Chip padding stays snug. The dismiss glyph is 14px; After uses a '
          '32×32 hit that overflows without changing chip metrics.',
      child: BeforeAfterSplit(
        before: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in labels)
              _FilterChip(
                label: label,
                dismiss: TightHitTarget(
                  onTap: () => setState(() => beforeTaps++),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: HitExampleTheme.ink.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
        after: HitScope(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels)
                _FilterChip(
                  label: label,
                  dismiss: ExpandedHitTarget(
                    onTap: () => setState(() => afterTaps++),
                    hitSize: const Size(32, 32),
                    paintChild: Icon(
                      Icons.close,
                      size: 14,
                      color: HitExampleTheme.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ),
            ],
          ),
        ),
        footer: TapStatsBar(
          beforeTaps: beforeTaps,
          afterTaps: afterTaps,
          hint: 'Try tapping slightly outside the × — After still counts.',
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.dismiss});

  final String label;
  final Widget dismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: HitExampleTheme.mist.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          dismiss,
        ],
      ),
    );
  }
}
