import 'package:flutter/cupertino.dart';
import 'package:hit/hit.dart';

void main() => runApp(const HitExampleApp());

class HitExampleApp extends StatelessWidget {
  const HitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'hit example',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: Color(0xFF0F6B5C),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: HitDemoPage(),
    );
  }
}

class HitDemoPage extends StatefulWidget {
  const HitDemoPage({super.key});

  @override
  State<HitDemoPage> createState() => _HitDemoPageState();
}

class _HitDemoPageState extends State<HitDemoPage> {
  int _iconTaps = 0;
  int _badgeTaps = 0;
  int _paintOnTopTaps = 0;
  bool _showHitArea = true;
  bool _useHit = true;
  bool _settingsOpen = false;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: HitScope(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 72, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'hit',
                          style: text.navLargeTitleTextStyle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Paint/layout size and hit size are separate. '
                          'Open Settings for Use hit / Show hit areas.',
                          style: text.textStyle.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildListDelegate([
                      _DemoTile(
                        title: 'HitLayer',
                        body: _useHit
                            ? 'Icon lays out at 24×24. Hit target is 48×48 — '
                                'neighbors stay put.'
                            : 'Same 24×24 icon. Tap target equals paint size — '
                                'corners outside the glyph miss.',
                        footer: '$_iconTaps taps',
                        child: ColoredBox(
                          color: const Color(0xFFFFE082),
                          child: Row(
                            children: [
                              if (_useHit)
                                HitLayer(
                                  alignment: Alignment.center,
                                  behavior: HitTestBehavior.deferToChild,
                                  hitChild: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _iconTaps++),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: _showHitArea ? const _HitGhost() : null,
                                    ),
                                  ),
                                  paintChild: const IgnorePointer(
                                    child: Icon(CupertinoIcons.add, size: 24),
                                  ),
                                )
                              else
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _iconTaps++),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const Icon(CupertinoIcons.add, size: 24),
                                        if (_showHitArea)
                                          const IgnorePointer(child: _HitGhost()),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('New item')),
                            ],
                          ),
                        ),
                      ),
                      _DemoTile(
                        title: 'Hit.defer',
                        body: _useHit
                            ? 'Badge hangs outside the card. '
                                'HitScope still delivers the tap.'
                            : 'Badge hangs outside the card. '
                                'Taps outside the parent bounds miss.',
                        footer: '$_badgeTaps taps',
                        child: _OverflowBadge(
                          useHit: _useHit,
                          showHitArea: _showHitArea,
                          paintOnTop: false,
                          onTap: () => setState(() => _badgeTaps++),
                        ),
                      ),
                      _DemoTile(
                        title: 'Hit.defer · paintOnTop',
                        body: _useHit
                            ? 'A cover sits above the badge in the tree. '
                                'paintOnTop still draws the badge last.'
                            : 'A cover sits above the badge in the tree. '
                                'Without paintOnTop the badge stays buried.',
                        footer: '$_paintOnTopTaps taps',
                        child: _OverflowBadge(
                          useHit: _useHit,
                          showHitArea: _showHitArea,
                          paintOnTop: true,
                          onTap: () => setState(() => _paintOnTopTaps++),
                          cover: true,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            if (_settingsOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _settingsOpen = false),
                  child: const ColoredBox(color: Color(0x33000000)),
                ),
              ),
            Positioned(
              top: 48,
              right: 16,
              child: _SettingsMenuButton(
                open: _settingsOpen,
                useHit: _useHit,
                showHitArea: _showHitArea,
                onOpenChanged: (v) => setState(() => _settingsOpen = v),
                onUseHitChanged: (v) => setState(() => _useHit = v),
                onShowHitAreaChanged: (v) => setState(() => _showHitArea = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gear + iOS-style popover. Menu hangs outside the button and uses [Hit.defer].
class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
    required this.open,
    required this.useHit,
    required this.showHitArea,
    required this.onOpenChanged,
    required this.onUseHitChanged,
    required this.onShowHitAreaChanged,
  });

  final bool open;
  final bool useHit;
  final bool showHitArea;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<bool> onUseHitChanged;
  final ValueChanged<bool> onShowHitAreaChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onOpenChanged(!open),
            child: Icon(
              CupertinoIcons.gear_solid,
              size: 22,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
          if (open)
            Positioned(
              top: 44,
              right: 0,
              child: Hit.defer(
                paintOnTop: true,
                behavior: HitTestBehavior.opaque,
                child: _SettingsPopover(
                  useHit: useHit,
                  showHitArea: showHitArea,
                  onUseHitChanged: onUseHitChanged,
                  onShowHitAreaChanged: onShowHitAreaChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsPopover extends StatelessWidget {
  const _SettingsPopover({
    required this.useHit,
    required this.showHitArea,
    required this.onUseHitChanged,
    required this.onShowHitAreaChanged,
  });

  final bool useHit;
  final bool showHitArea;
  final ValueChanged<bool> onUseHitChanged;
  final ValueChanged<bool> onShowHitAreaChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsToggle(
            title: 'Use hit',
            subtitle: useHit
                ? 'HitLayer / Hit.defer active'
                : 'Plain Flutter — no hit package',
            value: useHit,
            onChanged: onUseHitChanged,
          ),
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _SettingsToggle(
            title: 'Show hit areas',
            subtitle: showHitArea
                ? 'Green dashed outline = tappable region'
                : 'Hit areas hidden',
            value: showHitArea,
            onChanged: onShowHitAreaChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.tabLabelTextStyle.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.body,
    required this.footer,
    required this.child,
  });

  final String title;
  final String body;
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: text.tabLabelTextStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
          const SizedBox(height: 8),
          Text(footer, style: text.textStyle.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.useHit,
    required this.showHitArea,
    required this.paintOnTop,
    required this.onTap,
    this.cover = false,
  });

  final bool useHit;
  final bool showHitArea;
  final bool paintOnTop;
  final VoidCallback onTap;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;

    Widget badge = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.white,
                  width: 3,
                ),
              ),
              child: const Icon(
                CupertinoIcons.add,
                size: 16,
                color: CupertinoColors.white,
              ),
            ),
            if (showHitArea)
              const IgnorePointer(child: _HitGhost(circular: true)),
          ],
        ),
      ),
    );

    if (useHit) {
      badge = Hit.defer(
        paintOnTop: paintOnTop,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(cover ? 'Covered card' : 'Card'),
              ),
            ),
          ),
          Positioned(right: -12, top: -12, child: badge),
          if (cover)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text(
                    'cover',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HitGhost extends StatelessWidget {
  const _HitGhost({this.circular = false});

  final bool circular;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HitGhostPainter(circular: circular));
  }
}

class _HitGhostPainter extends CustomPainter {
  _HitGhostPainter({required this.circular});

  final bool circular;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = circular
        ? RRect.fromRectAndRadius(
            Offset.zero & size,
            Radius.circular(size.shortestSide / 2),
          )
        : RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(shape, Paint()..color = const Color(0x330F6B5C));
    final stroke = Paint()
      ..color = const Color(0xFF0F6B5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(shape.deflate(0.6));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + 4).clamp(0, metric.length)),
          stroke,
        );
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HitGhostPainter oldDelegate) =>
      oldDelegate.circular != circular;
}
