import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Trailing list icons that stay flush to content width.
class ListActionsDemo extends StatefulWidget {
  const ListActionsDemo({super.key});

  @override
  State<ListActionsDemo> createState() => _ListActionsDemoState();
}

class _ListActionsDemoState extends State<ListActionsDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  String last = '—';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'List row actions',
      subtitle:
          'Trailing icons are 18px. After expands each to 44×44 so thumbs hit '
          'reliably without adding horizontal padding to the row.',
      child: BeforeAfterSplit(
        before: _Rows(
          actionBuilder: (icon, name) => TightHitTarget(
            onTap: () => setState(() {
              beforeTaps++;
              last = 'before · $name';
            }),
            child: Icon(icon, size: 18, color: HitExampleTheme.ink),
          ),
        ),
        after: HitScope(
          child: _Rows(
            actionBuilder: (icon, name) => ExpandedHitTarget(
              onTap: () => setState(() {
                afterTaps++;
                last = 'after · $name';
              }),
              hitSize: const Size(44, 44),
              paintChild: Icon(icon, size: 18, color: HitExampleTheme.ink),
            ),
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Last action: $last',
                style: TextStyle(
                  fontSize: 12,
                  color: HitExampleTheme.ink.withValues(alpha: 0.55),
                ),
              ),
            ),
            TapStatsBar(beforeTaps: beforeTaps, afterTaps: afterTaps),
          ],
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.actionBuilder});

  final Widget Function(IconData icon, String name) actionBuilder;

  static const items = [
    ('Inbox zero', '3 new'),
    ('Design review', 'Today'),
    ('Ship checklist', 'Blocked'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HitExampleTheme.mist),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: HitExampleTheme.ink.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionBuilder(Icons.star_border, 'star'),
                  const SizedBox(width: 2),
                  actionBuilder(Icons.more_horiz, 'more'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
