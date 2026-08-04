import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:hit/hit.dart';

const primaryColor = CupertinoColors.destructiveRed;

void main() => runApp(const HitExampleApp());

class HitExampleApp extends StatelessWidget {
  const HitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'hit example',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(primaryColor: primaryColor),
      home: HitHome(),
    );
  }
}

/// Tab shell: Basics demos + SliverHitScope list/grid demos. Shared settings.
class HitHome extends StatefulWidget {
  const HitHome({super.key});

  @override
  State<HitHome> createState() => _HitHomeState();
}

class _HitHomeState extends State<HitHome> {
  bool _showHitArea = true;
  bool _useHit = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            label: 'Basics',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Slivers',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => HitDemoPage(
                useHit: _useHit,
                showHitArea: _showHitArea,
                onUseHitChanged: (v) => setState(() => _useHit = v),
                onShowHitAreaChanged: (v) => setState(() => _showHitArea = v),
              ),
              _ => SliverHitDemoPage(
                useHit: _useHit,
                showHitArea: _showHitArea,
                onUseHitChanged: (v) => setState(() => _useHit = v),
                onShowHitAreaChanged: (v) => setState(() => _showHitArea = v),
              ),
            };
          },
        );
      },
    );
  }
}

class HitDemoPage extends StatefulWidget {
  const HitDemoPage({
    super.key,
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
  State<HitDemoPage> createState() => _HitDemoPageState();
}

class _HitDemoPageState extends State<HitDemoPage> {
  int _iconTaps = 0;
  int _badgeTaps = 0;
  int _paintOnTopTaps = 0;
  int _chipTaps = 0;
  int _richTextTaps = 0;
  int _listTaps = 0;
  int _tightWrongTaps = 0;
  int _tightRightTaps = 0;
  int _clipWrongTaps = 0;
  int _clipRightTaps = 0;
  int _missingWrongTaps = 0;
  int _missingRightTaps = 0;
  bool _scrollLocked = false;
  double _sliderValue = 0.45;
  Size _panelSize = const Size(140, 88);
  double _windowWidth = 150;

  /// Orphan link — nothing walks it, so deferred hits never fire.
  final HitLink _orphanLink = HitLink();

  bool get _useHit => widget.useHit;
  bool get _showHitArea => widget.showHitArea;

  void _setScrollLocked(bool locked) {
    if (_scrollLocked == locked) return;
    setState(() => _scrollLocked = locked);
  }

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: HitScope(
        child: CustomScrollView(
          // Scrubbers (slider / edge / handle) lock scroll so the page
          // does not steal the gesture on small touch screens.
          physics: _scrollLocked
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('hit'),
              trailing: _SettingsMenuButton(
                useHit: widget.useHit,
                showHitArea: widget.showHitArea,
                onUseHitChanged: widget.onUseHitChanged,
                onShowHitAreaChanged: widget.onShowHitAreaChanged,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Paint/layout size and hit size are separate. '
                  'Open Settings for Use hit / Show hit areas. '
                  'Slivers tab demos SliverHitScope with list and grid.',
                  style: text.textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _DemoTile(
                    title: 'HitLayer',
                    body: _useHit
                        ? 'Icon lays out at 24x24. Hit target is 48x48 — '
                              'neighbors stay put.'
                        : 'Same 24x24 icon. Tap target equals paint size — '
                              'corners outside the glyph miss.',
                    footer: '$_iconTaps taps',
                    child: ColoredBox(
                      color: CupertinoColors.secondarySystemBackground
                          .resolveFrom(context),
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
                                  child: _showHitArea
                                      ? const _HitGhost()
                                      : null,
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
                    title: 'HitDefer',
                    body: _useHit
                        ? 'Badge hangs outside the card. '
                              'HitScope still delivers the tap.'
                        : 'Badge hangs outside the card. '
                              'Taps outside the parent bounds miss.',
                    footer: '$_badgeTaps taps',
                    child: _OverflowBadge(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      paint: HitDeferPaint.none,
                      onTap: () => setState(() => _badgeTaps++),
                    ),
                  ),
                  _DemoTile(
                    title: 'HitDefer · paint: onTop',
                    body: _useHit
                        ? 'A cover sits above the badge in the tree. '
                              'HitDeferPaint.onTop still draws the badge last.'
                        : 'A cover sits above the badge in the tree. '
                              'Without onTop paint the badge stays buried.',
                    footer: '$_paintOnTopTaps taps',
                    // HitScope wraps the whole tile so the hanging badge
                    // stays inside scope layout (tile padding absorbs -12).
                    scope: true,
                    child: _OverflowBadge(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      paint: HitDeferPaint.onTop,
                      onTap: () => setState(() => _paintOnTopTaps++),
                      cover: true,
                    ),
                  ),
                  _DemoTile(
                    title: 'Chip dismiss',
                    body: _useHit
                        ? 'Dense chip stays tight; x hit expands to 44x44.'
                        : 'x is only as big as the glyph — easy to miss.',
                    footer: '$_chipTaps dismisses',
                    child: _ChipDismiss(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      onDismiss: () => setState(() => _chipTaps++),
                    ),
                  ),
                  _DemoTile(
                    title: 'Text.rich · WidgetSpan',
                    body: _useHit
                        ? 'Inline @mention lays out tight in Text.rich; '
                              'hit expands past the placeholder.'
                        : 'Inline @mention hit equals paint — corners miss.',
                    footer: '$_richTextTaps taps',
                    child: _RichTextHit(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _richTextTaps++),
                    ),
                  ),
                  _DemoTile(
                    title: 'Resize handle',
                    body: _useHit
                        ? 'Drag the tiny grip — hit expands outside the panel.'
                        : 'Grip hit equals paint — hard to grab and drag.',
                    footer:
                        '${_panelSize.width.round()}x${_panelSize.height.round()}',
                    child: _ResizeHandle(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      size: _panelSize,
                      onDraggingChanged: _setScrollLocked,
                      onSizeChanged: (s) => setState(() => _panelSize = s),
                    ),
                  ),
                  _DemoTile(
                    title: 'Window edge',
                    body: _useHit
                        ? 'Drag the 1px edge — thick hit strip expands outside.'
                        : 'Only the 1px line receives drag hits.',
                    footer: '${_windowWidth.round()} wide',
                    child: _WindowEdge(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      width: _windowWidth,
                      onDraggingChanged: _setScrollLocked,
                      onWidthChanged: (w) => setState(() => _windowWidth = w),
                    ),
                  ),
                  _DemoTile(
                    title: 'List row action',
                    body: _useHit
                        ? 'Trailing icon sits flush; hit expands outward.'
                        : 'Trailing icon hit equals glyph size.',
                    footer: '$_listTaps actions',
                    child: _ListAction(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _listTaps++),
                    ),
                  ),
                  _DemoTile(
                    title: 'Slider thumb',
                    body: _useHit
                        ? 'Small thumb for polish; oversized hit for scrubbing.'
                        : 'Thumb hit equals paint — scrubbing is fiddly.',
                    footer: '${(_sliderValue * 100).round()}%',
                    child: _SliderThumb(
                      useHit: _useHit,
                      showHitArea: _showHitArea,
                      value: _sliderValue,
                      onDraggingChanged: _setScrollLocked,
                      onChanged: (v) => setState(() => _sliderValue = v),
                    ),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common mistakes',
                      style: text.navTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Flutter only hit-tests inside a child’s layout box. '
                      'HitScope can deliver overflow taps — but only if '
                      'events reach a scope that covers them. Try the '
                      'corners on Wrong vs Right.',
                      style: text.textStyle.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList.list(
                children: [
                  _MistakeCompare(
                    title: 'Scope too small',
                    body:
                        'Wrapping HitScope only around the 24×24 paint '
                        'leaves the 48×48 hit outside the scope. Parents '
                        'never walk there — pad under the scope (or lift '
                        'it) so the overflow stays inside.',
                    wrongFooter: '$_tightWrongTaps taps',
                    rightFooter: '$_tightRightTaps taps',
                    wrong: _TightScopeDemo(
                      padded: false,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _tightWrongTaps++),
                    ),
                    right: _TightScopeDemo(
                      padded: true,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _tightRightTaps++),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MistakeCompare(
                    title: 'Clip above HitScope',
                    body:
                        'ClipRect / a tight box above HitScope blocks the '
                        'walk before deferred hits run. Put HitScope '
                        'above the clip, or drop the clip and pad so the '
                        'hanging control stays inside the scope.',
                    wrongFooter: '$_clipWrongTaps taps',
                    rightFooter: '$_clipRightTaps taps',
                    wrong: _ClipScopeDemo(
                      clipped: true,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _clipWrongTaps++),
                    ),
                    right: _ClipScopeDemo(
                      clipped: false,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _clipRightTaps++),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MistakeCompare(
                    title: 'Missing HitScope',
                    body:
                        'Overflowing HitLayer needs a HitScope (or a link '
                        'owned by one). Wrong uses an orphan HitLink — '
                        'nothing delivers deferred hits. Right wraps a '
                        'covering HitScope.',
                    wrongFooter: '$_missingWrongTaps taps',
                    rightFooter: '$_missingRightTaps taps',
                    wrong: _MissingScopeDemo(
                      link: _orphanLink,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _missingWrongTaps++),
                    ),
                    right: _MissingScopeDemo(
                      link: null,
                      showHitArea: _showHitArea,
                      onTap: () => setState(() => _missingRightTaps++),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo tab: overflowing hits delivered by [SliverHitScope] inside a
/// [CustomScrollView] — [SliverList] rows and [SliverGrid] cells.
class SliverHitDemoPage extends StatefulWidget {
  const SliverHitDemoPage({
    super.key,
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
  State<SliverHitDemoPage> createState() => _SliverHitDemoPageState();
}

class _SliverHitDemoPageState extends State<SliverHitDemoPage> {
  final Map<int, int> _listTaps = <int, int>{};
  final Map<int, int> _gridTaps = <int, int>{};

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Slivers'),
            trailing: _SettingsMenuButton(
              useHit: widget.useHit,
              showHitArea: widget.showHitArea,
              onUseHitChanged: widget.onUseHitChanged,
              onShowHitAreaChanged: widget.onShowHitAreaChanged,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                widget.useHit
                    ? 'List and grid sit under SliverHitScope. '
                          'Trash / icon paint stays small; expanded hits '
                          'still work while you scroll.'
                    : 'Same SliverHitScope, but controls use paint-sized '
                          'hits only — corners outside the glyph miss.',
                style: text.textStyle.copyWith(color: secondary),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'SliverList',
                style: text.navTitleTextStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverHitScope(
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList.builder(
                itemCount: 24,
                itemBuilder: (context, index) {
                  final taps = _listTaps[index] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SliverInboxRow(
                      index: index,
                      taps: taps,
                      useHit: widget.useHit,
                      showHitArea: widget.showHitArea,
                      onTap: () => setState(() {
                        _listTaps[index] = taps + 1;
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SliverGrid',
                    style: text.navTitleTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Each cell paints a 24×24 glyph with a 48×48 hit. '
                    'Neighbors keep their layout.',
                    style: text.textStyle.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
          ),
          SliverHitScope(
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final taps = _gridTaps[index] ?? 0;
                  return _SliverGridCell(
                    index: index,
                    taps: taps,
                    useHit: widget.useHit,
                    showHitArea: widget.showHitArea,
                    onTap: () => setState(() {
                      _gridTaps[index] = taps + 1;
                    }),
                  );
                }, childCount: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverInboxRow extends StatelessWidget {
  const _SliverInboxRow({
    required this.index,
    required this.taps,
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final int index;
  final int taps;
  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: label),
                ),
                const SizedBox(height: 2),
                Text(
                  taps == 0 ? 'Tap the trash corner' : '$taps deletes',
                  style: TextStyle(fontSize: 13, color: secondary),
                ),
              ],
            ),
          ),
          _ExpandHit(
            useHit: useHit,
            showHitArea: showHitArea,
            onTap: onTap,
            hitSize: const Size(48, 48),
            paintChild: Icon(
              CupertinoIcons.trash,
              size: 20,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverGridCell extends StatelessWidget {
  const _SliverGridCell({
    required this.index,
    required this.taps,
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final int index;
  final int taps;
  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  static const _icons = <IconData>[
    CupertinoIcons.heart,
    CupertinoIcons.star,
    CupertinoIcons.bookmark,
    CupertinoIcons.flag,
    CupertinoIcons.bell,
    CupertinoIcons.tag,
  ];

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final icon = _icons[index % _icons.length];

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (useHit)
            HitLayer(
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: showHitArea ? const _HitGhost() : null,
                ),
              ),
              paintChild: IgnorePointer(child: Icon(icon, size: 24)),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Icon(icon, size: 24),
            ),
          const SizedBox(height: 8),
          Text(
            taps == 0 ? '#${index + 1}' : '$taps',
            style: TextStyle(fontSize: 13, color: secondary),
          ),
        ],
      ),
    );
  }
}

/// Settings gear that opens a [CupertinoMenuAnchor] with toggle items.
class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
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
    return CupertinoMenuAnchor(
      consumeOutsideTaps: true,
      builder: (context, controller, child) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: const Icon(CupertinoIcons.settings),
        );
      },
      menuChildren: [
        CupertinoMenuItem(
          subtitle: Text(
            useHit
                ? 'HitLayer / HitDefer active'
                : 'Plain Flutter — no hit package',
          ),
          trailing: useHit
              ? const Icon(CupertinoIcons.check_mark)
              : const SizedBox.shrink(),
          requestCloseOnActivate: false,
          onPressed: () => onUseHitChanged(!useHit),
          child: const Text('Use hit'),
        ),
        const CupertinoMenuDivider(),
        CupertinoMenuItem(
          subtitle: Text(
            showHitArea
                ? 'Green dashed outline = tappable region'
                : 'Hit areas hidden',
          ),
          trailing: showHitArea
              ? const Icon(CupertinoIcons.check_mark)
              : const SizedBox.shrink(),
          requestCloseOnActivate: false,
          onPressed: () => onShowHitAreaChanged(!showHitArea),
          child: const Text('Show hit areas'),
        ),
      ],
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.body,
    required this.footer,
    required this.child,
    this.scope = false,
  });

  final String title;
  final String body;
  final String footer;
  final Widget child;
  final bool scope;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    Widget tile = Container(
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
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: text.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (scope) {
      tile = HitScope(child: tile);
    }
    return tile;
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.useHit,
    required this.showHitArea,
    required this.paint,
    required this.onTap,
    this.cover = false,
  });

  final bool useHit;
  final bool showHitArea;
  final HitDeferPaint paint;
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
                border: Border.all(color: CupertinoColors.white, width: 3),
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
      badge = switch (paint) {
        HitDeferPaint.onTop => HitDefer(
          paint: HitDeferPaint.onTop,
          behavior: HitTestBehavior.opaque,
          child: badge,
        ),
        HitDeferPaint.none => HitDefer(
          behavior: HitTestBehavior.opaque,
          child: badge,
        ),
      };
    }

    final coverLayer = cover
        ? Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
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
          )
        : null;

    // Badge first so without HitDeferPaint.onTop the cover buries it.
    final List<Widget> stackChildren = [
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
      ?coverLayer,
    ];

    return SizedBox(
      width: double.infinity,
      height: 110,
      child: Stack(clipBehavior: Clip.none, children: stackChildren),
    );
  }
}

/// Shared HitLayer / plain-Flutter control used by several demos.
class _ExpandHit extends StatelessWidget {
  const _ExpandHit({
    required this.useHit,
    required this.showHitArea,
    required this.paintChild,
    this.onTap,
    this.hitSize = const Size(44, 44),
    this.alignment = Alignment.center,
    this.drag = _ExpandDrag.none,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.cursor,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback? onTap;
  final _ExpandDrag drag;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final VoidCallback? onDragCancel;
  final Widget paintChild;
  final Size hitSize;
  final Alignment alignment;
  final MouseCursor? cursor;

  @override
  Widget build(BuildContext context) {
    Widget interact({required Widget child}) {
      Widget detector = child;
      if (drag != _ExpandDrag.none) {
        // Accept immediately so the page scroll view cannot steal the scrub.
        detector = RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            if (drag == _ExpandDrag.horizontal)
              _EagerHorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _EagerHorizontalDragGestureRecognizer
                  >(() => _EagerHorizontalDragGestureRecognizer(), (
                    _EagerHorizontalDragGestureRecognizer instance,
                  ) {
                    instance
                      ..onStart = onDragStart
                      ..onUpdate = onDragUpdate
                      ..onEnd = onDragEnd
                      ..onCancel = onDragCancel;
                  }),
            if (drag == _ExpandDrag.pan)
              _EagerPanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _EagerPanGestureRecognizer
                  >(() => _EagerPanGestureRecognizer(), (
                    _EagerPanGestureRecognizer instance,
                  ) {
                    instance
                      ..onStart = onDragStart
                      ..onUpdate = onDragUpdate
                      ..onEnd = onDragEnd
                      ..onCancel = onDragCancel;
                  }),
          },
          child: child,
        );
      }
      if (onTap != null) {
        detector = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: detector,
        );
      } else if (drag == _ExpandDrag.none) {
        detector = GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: detector,
        );
      }
      if (cursor == null) return detector;
      return MouseRegion(cursor: cursor!, child: detector);
    }

    if (!useHit) {
      return interact(
        child: Stack(
          alignment: Alignment.center,
          children: [
            paintChild,
            if (showHitArea)
              const Positioned.fill(child: IgnorePointer(child: _HitGhost())),
          ],
        ),
      );
    }

    return HitLayer(
      alignment: alignment,
      behavior: HitTestBehavior.deferToChild,
      hitChild: interact(
        child: SizedBox(
          width: hitSize.width,
          height: hitSize.height,
          child: showHitArea ? const _HitGhost() : null,
        ),
      ),
      paintChild: IgnorePointer(child: paintChild),
    );
  }
}

enum _ExpandDrag { none, pan, horizontal }

/// Wins the arena on pointer down so nested scrollables cannot steal scrubs.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _EagerHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _ChipDismiss extends StatelessWidget {
  const _ChipDismiss({
    required this.useHit,
    required this.showHitArea,
    required this.onDismiss,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Design',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            _ExpandHit(
              useHit: useHit,
              showHitArea: showHitArea,
              onTap: onDismiss,
              hitSize: const Size(44, 44),
              paintChild: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 18,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [HitLayer] inside [Text.rich] / [WidgetSpan] — layout follows the chip;
/// overflow taps still land via the enclosing [HitScope].
class _RichTextHit extends StatelessWidget {
  const _RichTextHit({
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final baseStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      fontSize: 15,
      height: 1.4,
      color: secondary,
    );

    final mention = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '@hit',
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.2,
        ),
      ),
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'Ping '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _ExpandHit(
              useHit: useHit,
              showHitArea: showHitArea,
              onTap: onTap,
              hitSize: const Size(44, 44),
              paintChild: mention,
            ),
          ),
          const TextSpan(text: ' without growing the line box.'),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.useHit,
    required this.showHitArea,
    required this.size,
    required this.onSizeChanged,
    required this.onDraggingChanged,
  });

  final bool useHit;
  final bool showHitArea;
  final Size size;
  final ValueChanged<Size> onSizeChanged;
  final ValueChanged<bool> onDraggingChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 120.0;
        final w = size.width.clamp(72.0, maxW);
        final h = size.height.clamp(56.0, maxH);

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Panel'),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _ExpandHit(
                    useHit: useHit,
                    showHitArea: showHitArea,
                    hitSize: const Size(44, 44),
                    alignment: Alignment.center,
                    cursor: SystemMouseCursors.resizeUpLeftDownRight,
                    drag: _ExpandDrag.pan,
                    onDragStart: (_) => onDraggingChanged(true),
                    onDragEnd: (_) => onDraggingChanged(false),
                    onDragCancel: () => onDraggingChanged(false),
                    onDragUpdate: (details) {
                      onSizeChanged(
                        Size(
                          (w + details.delta.dx).clamp(72.0, maxW),
                          (h + details.delta.dy).clamp(56.0, maxH),
                        ),
                      );
                    },
                    paintChild: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: CupertinoTheme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WindowEdge extends StatelessWidget {
  const _WindowEdge({
    required this.useHit,
    required this.showHitArea,
    required this.width,
    required this.onWidthChanged,
    required this.onDraggingChanged,
  });

  final bool useHit;
  final bool showHitArea;
  final double width;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<bool> onDraggingChanged;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final w = width.clamp(80.0, maxW);
        const height = 96.0;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: w,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: const Center(child: Text('Window')),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: _ExpandHit(
                    useHit: useHit,
                    showHitArea: showHitArea,
                    // Wide enough for a thumb; expands outside the window.
                    hitSize: const Size(28, height),
                    alignment: Alignment.center,
                    cursor: SystemMouseCursors.resizeLeftRight,
                    drag: _ExpandDrag.horizontal,
                    onDragStart: (_) => onDraggingChanged(true),
                    onDragEnd: (_) => onDraggingChanged(false),
                    onDragCancel: () => onDraggingChanged(false),
                    onDragUpdate: (details) {
                      onWidthChanged((w + details.delta.dx).clamp(80.0, maxW));
                    },
                    paintChild: Container(
                      width: 1,
                      height: height,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListAction extends StatelessWidget {
  const _ListAction({
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Inbox message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ExpandHit(
            useHit: useHit,
            showHitArea: showHitArea,
            onTap: onTap,
            hitSize: const Size(44, 44),
            paintChild: Icon(
              CupertinoIcons.trash,
              size: 18,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderThumb extends StatelessWidget {
  const _SliderThumb({
    required this.useHit,
    required this.showHitArea,
    required this.value,
    required this.onChanged,
    required this.onDraggingChanged,
  });

  final bool useHit;
  final bool showHitArea;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onDraggingChanged;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbX = value.clamp(0.0, 1.0) * trackWidth;

        return SizedBox(
          height: 48,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                width: trackWidth,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 4,
                width: thumbX,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                left: thumbX - 6,
                child: _ExpandHit(
                  useHit: useHit,
                  showHitArea: showHitArea,
                  hitSize: const Size(44, 44),
                  drag: _ExpandDrag.horizontal,
                  onDragStart: (_) => onDraggingChanged(true),
                  onDragEnd: (_) => onDraggingChanged(false),
                  onDragCancel: () => onDraggingChanged(false),
                  onDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null || !box.hasSize || trackWidth <= 0) {
                      return;
                    }
                    final local = box.globalToLocal(details.globalPosition);
                    onChanged((local.dx / trackWidth).clamp(0.0, 1.0));
                  },
                  paintChild: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MistakeCompare extends StatelessWidget {
  const _MistakeCompare({
    required this.title,
    required this.body,
    required this.wrong,
    required this.right,
    required this.wrongFooter,
    required this.rightFooter,
  });

  final String title;
  final String body;
  final Widget wrong;
  final Widget right;
  final String wrongFooter;
  final String rightFooter;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MistakeSide(
                  label: 'Wrong',
                  ok: false,
                  footer: wrongFooter,
                  child: wrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MistakeSide(
                  label: 'Right',
                  ok: true,
                  footer: rightFooter,
                  child: right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MistakeSide extends StatelessWidget {
  const _MistakeSide({
    required this.label,
    required this.ok,
    required this.footer,
    required this.child,
  });

  final String label;
  final bool ok;
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    final accent = ok
        ? CupertinoColors.activeGreen.resolveFrom(context)
        : CupertinoColors.destructiveRed.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.tabLabelTextStyle.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: child,
        ),
        const SizedBox(height: 8),
        Text(
          footer,
          style: text.textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Shared 24 paint / 48 hit icon used by mistake demos.
class _MistakeIconLayer extends StatelessWidget {
  const _MistakeIconLayer({
    required this.showHitArea,
    required this.onTap,
    this.link,
  });

  final bool showHitArea;
  final VoidCallback onTap;
  final HitLink? link;

  @override
  Widget build(BuildContext context) {
    return HitLayer(
      link: link,
      alignment: Alignment.center,
      behavior: HitTestBehavior.deferToChild,
      hitChild: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: showHitArea ? const _HitGhost() : null,
        ),
      ),
      paintChild: const IgnorePointer(
        child: Icon(CupertinoIcons.add, size: 24),
      ),
    );
  }
}

class _TightScopeDemo extends StatelessWidget {
  const _TightScopeDemo({
    required this.padded,
    required this.showHitArea,
    required this.onTap,
  });

  final bool padded;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layer = _MistakeIconLayer(showHitArea: showHitArea, onTap: onTap);
    // Nested HitScope so the page-level scope does not rescue the tight case.
    return HitScope(
      child: padded
          ? Padding(padding: const EdgeInsets.all(12), child: layer)
          : layer,
    );
  }
}

class _ClipScopeDemo extends StatelessWidget {
  const _ClipScopeDemo({
    required this.clipped,
    required this.showHitArea,
    required this.onTap,
  });

  final bool clipped;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Card', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
          Positioned(
            right: -14,
            top: -14,
            child: HitDefer(
              behavior: HitTestBehavior.opaque,
              child: GestureDetector(
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
                          color: CupertinoTheme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          size: 14,
                          color: CupertinoColors.white,
                        ),
                      ),
                      if (showHitArea)
                        const IgnorePointer(child: _HitGhost(circular: true)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (clipped) {
      // Clip above HitScope — overflow never receives events.
      return ClipRect(
        child: SizedBox(width: 72, height: 72, child: HitScope(child: card)),
      );
    }

    // HitScope covers the hanging badge via padding; no clip above.
    return HitScope(
      child: Padding(padding: const EdgeInsets.all(16), child: card),
    );
  }
}

class _MissingScopeDemo extends StatelessWidget {
  const _MissingScopeDemo({
    required this.link,
    required this.showHitArea,
    required this.onTap,
  });

  /// Non-null orphan link = Wrong (nothing walks it). Null = use HitScope.
  final HitLink? link;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layer = _MistakeIconLayer(
      link: link,
      showHitArea: showHitArea,
      onTap: onTap,
    );
    if (link != null) {
      // Deliberately no HitScope on this link — deferred hits never fire.
      return Padding(padding: const EdgeInsets.all(12), child: layer);
    }
    return HitScope(
      child: Padding(padding: const EdgeInsets.all(12), child: layer),
    );
  }
}

class _HitGhost extends StatelessWidget {
  const _HitGhost({this.circular = false});

  final bool circular;

  @override
  Widget build(BuildContext context) {
    final color = primaryColor.resolveFrom(context);
    return CustomPaint(
      painter: _HitGhostPainter(
        circular: circular,
        fill: color.withValues(alpha: 0.2),
        stroke: color,
      ),
    );
  }
}

class _HitGhostPainter extends CustomPainter {
  _HitGhostPainter({
    required this.circular,
    required this.fill,
    required this.stroke,
  });

  final bool circular;
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = circular
        ? RRect.fromRectAndRadius(
            Offset.zero & size,
            Radius.circular(size.shortestSide / 2),
          )
        : RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(shape, Paint()..color = fill);
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final path = Path()..addRRect(shape.deflate(0.6));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + 4).clamp(0, metric.length)),
          paint,
        );
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HitGhostPainter oldDelegate) =>
      oldDelegate.circular != circular ||
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke;
}
