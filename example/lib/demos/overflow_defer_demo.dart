import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';

/// Control that hangs outside its parent — needs Hit.defer + HitScope.
class OverflowDeferDemo extends StatefulWidget {
  const OverflowDeferDemo({super.key});

  @override
  State<OverflowDeferDemo> createState() => _OverflowDeferDemoState();
}

class _OverflowDeferDemoState extends State<OverflowDeferDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Overflow control',
      subtitle:
          'A badge sits outside a card. Without Hit.defer, taps outside the '
          'parent bounds miss. After registers the deferred target on HitScope.',
      child: BeforeAfterSplit(
        before: _CardWithBadge(
          deferred: false,
          onBadgeTap: () => setState(() => beforeTaps++),
        ),
        after: HitScope(
          child: _CardWithBadge(
            deferred: true,
            onBadgeTap: () => setState(() => afterTaps++),
          ),
        ),
        footer: TapStatsBar(
          beforeTaps: beforeTaps,
          afterTaps: afterTaps,
          hint: 'Tap the floating badge that hangs off the card corner.',
        ),
      ),
    );
  }
}

class _CardWithBadge extends StatelessWidget {
  const _CardWithBadge({required this.deferred, required this.onBadgeTap});

  final bool deferred;
  final VoidCallback onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final badge = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBadgeTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: deferred ? HitExampleTheme.accent : HitExampleTheme.warn,
          shape: BoxShape.circle,
          border: Border.all(color: HitExampleTheme.paper, width: 3),
          boxShadow: [
            BoxShadow(
              color: HitExampleTheme.ink.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 16, color: Colors.white),
      ),
    );

    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HitExampleTheme.mist),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deferred ? 'Hit.defer' : 'plain Stack',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deferred
                          ? 'Overflow taps route through HitScope.'
                          : 'Parent clips hit tests to its bounds.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: HitExampleTheme.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -14,
            top: -14,
            child: deferred
                ? Hit.defer(behavior: HitTestBehavior.opaque, child: badge)
                : badge,
          ),
        ],
      ),
    );
  }
}
