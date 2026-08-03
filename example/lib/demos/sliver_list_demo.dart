import 'package:flutter/material.dart';
import 'package:hit/hit.dart';

import '../theme.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/hit_target.dart';

/// Expanded hit targets inside a [CustomScrollView] / [SliverList].
///
/// Wrap the scroll view (or another ancestor large enough to contain overflow)
/// in [HitScope] so taps that fall outside a row’s paint box still route to
/// the registered [HitLayer] while the list scrolls.
class SliverListDemo extends StatefulWidget {
  const SliverListDemo({super.key});

  @override
  State<SliverListDemo> createState() => _SliverListDemoState();
}

class _SliverListDemoState extends State<SliverListDemo> {
  int beforeTaps = 0;
  int afterTaps = 0;
  String last = '—';

  static const items = [
    ('Inbox zero', '3 new'),
    ('Design review', 'Today'),
    ('Ship checklist', 'Blocked'),
    ('Motion polish', 'In progress'),
    ('Hit targets', 'Docs'),
    ('Sliver pins', 'Pinned'),
    ('Toolbar density', 'Done'),
    ('Window edges', 'Review'),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Sliver list actions',
      subtitle:
          'CustomScrollView + SliverList rows keep 18px trailing icons. After '
          'puts HitScope around the scroll view so 44×44 hits still land while '
          'scrolling — including a pinned header control.',
      child: BeforeAfterSplit(
        before: _SliverPanel(
          expandHit: false,
          items: items,
          onAction: (name) => setState(() {
            beforeTaps++;
            last = 'before · $name';
          }),
        ),
        after: _SliverPanel(
          expandHit: true,
          items: items,
          onAction: (name) => setState(() {
            afterTaps++;
            last = 'after · $name';
          }),
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
            TapStatsBar(
              beforeTaps: beforeTaps,
              afterTaps: afterTaps,
              hint:
                  'Scroll, then tap near a trailing icon — green is the '
                  'expanded hit.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverPanel extends StatelessWidget {
  const _SliverPanel({
    required this.expandHit,
    required this.items,
    required this.onAction,
  });

  final bool expandHit;
  final List<(String, String)> items;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            expandHit: expandHit,
            onPin: () => onAction('pin header'),
          ),
        ),
        SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SliverRow(
              title: item.$1,
              subtitle: item.$2,
              expandHit: expandHit,
              onAction: onAction,
            );
          },
        ),
      ],
    );

    return SizedBox(
      width: 280,
      height: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HitExampleTheme.mist),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // HitScope must sit above the overflowing HitLayers and be large
          // enough that overflow taps still reach it (here: the viewport).
          child: expandHit ? HitScope(child: scrollView) : scrollView,
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({required this.expandHit, required this.onPin});

  final bool expandHit;
  final VoidCallback onPin;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final pin = expandHit
        ? ExpandedHitTarget(
            onTap: onPin,
            hitSize: const Size(40, 40),
            paintChild: Icon(
              Icons.push_pin_outlined,
              size: 16,
              color: HitExampleTheme.accent,
            ),
          )
        : TightHitTarget(
            onTap: onPin,
            child: Icon(
              Icons.push_pin_outlined,
              size: 16,
              color: HitExampleTheme.warn,
            ),
          );

    // Child must fill min/maxExtent or pinned geometry asserts
    // (layoutExtent > paintExtent).
    return SizedBox(
      height: maxExtent,
      child: ColoredBox(
        color: HitExampleTheme.mist.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  expandHit ? 'After · slivers' : 'Before · slivers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HitExampleTheme.ink.withValues(alpha: 0.7),
                  ),
                ),
              ),
              pin,
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.expandHit != expandHit;
  }
}

class _SliverRow extends StatelessWidget {
  const _SliverRow({
    required this.title,
    required this.subtitle,
    required this.expandHit,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final bool expandHit;
  final ValueChanged<String> onAction;

  Widget _action(IconData icon, String name) {
    if (expandHit) {
      return ExpandedHitTarget(
        onTap: () => onAction(name),
        hitSize: const Size(44, 44),
        paintChild: Icon(icon, size: 18, color: HitExampleTheme.ink),
      );
    }
    return TightHitTarget(
      onTap: () => onAction(name),
      child: Icon(icon, size: 18, color: HitExampleTheme.ink),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: HitExampleTheme.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          _action(Icons.star_border, 'star'),
          const SizedBox(width: 2),
          _action(Icons.more_horiz, 'more'),
        ],
      ),
    );
  }
}
