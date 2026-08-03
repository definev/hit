import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Browser-style tabs with a small close affordance.
class TabCloseDemo extends StatefulWidget {
  const TabCloseDemo({super.key});

  @override
  State<TabCloseDemo> createState() => _TabCloseDemoState();
}

class _TabCloseDemoState extends State<TabCloseDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  int selected = 1;

  static const tabs = ['Overview', 'Tokens', 'Motion', 'Ship'];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tab close',
      subtitle:
          'Tabs stay compact. Close is 12px visually; After expands to 36×36 '
          'anchored top-right so the label row doesn’t grow.',
      child: BeforeAfterSplit(
        before: _TabStrip(
          tabs: tabs,
          selected: selected,
          onSelect: (i) => setState(() => selected = i),
          closeBuilder: (_) => TightHitTarget(
            onTap: () => setState(() => beforeTaps++),
            child: Icon(
              Icons.close,
              size: 12,
              color: HitExampleTheme.ink.withValues(alpha: 0.5),
            ),
          ),
        ),
        after: HitScope(
          child: _TabStrip(
            tabs: tabs,
            selected: selected,
            onSelect: (i) => setState(() => selected = i),
            closeBuilder: (_) => ExpandedHitTarget(
              onTap: () => setState(() => afterTaps++),
              hitSize: const Size(36, 36),
              alignment: Alignment.center,
              paintChild: Icon(
                Icons.close,
                size: 12,
                color: HitExampleTheme.ink.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        footer: TapStatsBar(beforeTaps: beforeTaps, afterTaps: afterTaps),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required this.closeBuilder,
  });

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget Function(int index) closeBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: HitExampleTheme.mist.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _Tab(
              label: tabs[i],
              active: selected == i,
              onSelect: () => onSelect(i),
              close: closeBuilder(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onSelect,
    required this.close,
  });

  final String label;
  final bool active;
  final VoidCallback onSelect;
  final Widget close;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? HitExampleTheme.mist : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            close,
          ],
        ),
      ),
    );
  }
}
