import 'package:flutter/material.dart';

import 'demos/chip_dismiss_demo.dart';
import 'demos/icon_button_demo.dart';
import 'demos/list_actions_demo.dart';
import 'demos/overflow_defer_demo.dart';
import 'demos/resize_handle_demo.dart';
import 'demos/slider_thumb_demo.dart';
import 'demos/sliver_list_demo.dart';
import 'demos/tab_close_demo.dart';
import 'demos/toolbar_density_demo.dart';
import 'demos/window_edge_demo.dart';
import 'theme.dart';

class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String blurb;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<DemoEntry> kDemos = [
  DemoEntry(
    title: 'Icon button · 44×44 hit',
    blurb: 'Keep a 20–24px glyph; expand the tappable target to WCAG size.',
    icon: Icons.add,
    builder: (_) => const IconButtonDemo(),
  ),
  DemoEntry(
    title: 'Resize window handle',
    blurb: 'Tiny grip stays visually light; hit area is finger-friendly.',
    icon: Icons.open_with,
    builder: (_) => const ResizeHandleDemo(),
  ),
  DemoEntry(
    title: 'Window edge resize',
    blurb: '1px visual borders with thick invisible hit strips.',
    icon: Icons.crop_free,
    builder: (_) => const WindowEdgeDemo(),
  ),
  DemoEntry(
    title: 'Chip dismiss ×',
    blurb: 'Dense chips keep layout tight while the × remains easy to hit.',
    icon: Icons.cancel_outlined,
    builder: (_) => const ChipDismissDemo(),
  ),
  DemoEntry(
    title: 'Tab close',
    blurb: 'Browser-style tabs: small ×, large hit, no layout bloat.',
    icon: Icons.tab,
    builder: (_) => const TabCloseDemo(),
  ),
  DemoEntry(
    title: 'List row actions',
    blurb: 'Trailing icons sit flush to content; hit expands outward.',
    icon: Icons.more_horiz,
    builder: (_) => const ListActionsDemo(),
  ),
  DemoEntry(
    title: 'Sliver list actions',
    blurb:
        'HitScope around CustomScrollView — expanded hits survive scroll + pin.',
    icon: Icons.view_day_outlined,
    builder: (_) => const SliverListDemo(),
  ),
  DemoEntry(
    title: 'Slider thumb',
    blurb: 'Small thumb for polish; oversized hit for scrubbing accuracy.',
    icon: Icons.tune,
    builder: (_) => const SliderThumbDemo(),
  ),
  DemoEntry(
    title: 'Dense toolbar',
    blurb:
        'Icons pack visually; hits overlap neighbors without stealing layout.',
    icon: Icons.build_outlined,
    builder: (_) => const ToolbarDensityDemo(),
  ),
  DemoEntry(
    title: 'Overflow · Hit.defer',
    blurb: 'Badge hangs outside a card; deferred hits still register.',
    icon: Icons.picture_in_picture_alt_outlined,
    builder: (_) => const OverflowDeferDemo(),
  ),
];

class DemoCatalogPage extends StatelessWidget {
  const DemoCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'hit',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Before / after gallery for design engineers.\n'
                    'Layout follows paint size. Hit area can overflow via HitScope.',
                    style: TextStyle(
                      color: HitExampleTheme.ink.withValues(alpha: 0.65),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _LegendDot(
                        color: HitExampleTheme.beforeStroke,
                        label: 'Tight hit (before)',
                      ),
                      _LegendDot(
                        color: HitExampleTheme.hitStroke,
                        label: 'Expanded hit (after)',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList.separated(
              itemCount: kDemos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final demo = kDemos[index];
                return _DemoTile(demo: demo);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HitExampleTheme.ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _DemoTile extends StatefulWidget {
  const _DemoTile({required this.demo});

  final DemoEntry demo;

  @override
  State<_DemoTile> createState() => _DemoTileState();
}

class _DemoTileState extends State<_DemoTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: widget.demo.builder));
        },
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HitExampleTheme.mist),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: HitExampleTheme.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.demo.icon,
                    color: HitExampleTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.demo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.demo.blurb,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: HitExampleTheme.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: HitExampleTheme.ink.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
