part of '../main.dart';

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
  String? _lastToolbarAction;
  String? _lastMenuPick;
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
        debugLabel: 'basics-page',
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
            SliverHitScope(
              debugLabel: 'sliver-hit-scope',
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Paint/layout size and hit size are separate. '
                        'Open Settings for Use hit / Show hit areas. '
                        'Slivers tab demos SliverHitScope with list and grid.',
                        style: text.textStyle.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      delegate: SliverChildListDelegate([
                        _DemoTile(
                          title: 'Hover toolbar',
                          body: _useHit
                              ? 'Hover the card — toolbar hangs above it. '
                                    'HitDefer + HitScope still deliver taps '
                                    'outside the card box.'
                              : 'Toolbar hangs above the card. Without '
                                    'HitDefer, taps on the overhang miss.',
                          footer: _lastToolbarAction == null
                              ? 'Hover the card, then tap the bar'
                              : 'Last: $_lastToolbarAction',
                          child: _HoverToolbar(
                            useHit: _useHit,
                            showHitArea: _showHitArea,
                            onAction: (label) =>
                                setState(() => _lastToolbarAction = label),
                          ),
                        ),
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
                                    debugLabel: 'new-item',
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
                                          const Icon(
                                            CupertinoIcons.add,
                                            size: 24,
                                          ),
                                          if (_showHitArea)
                                            const IgnorePointer(
                                              child: _HitGhost(),
                                            ),
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
                            debugLabel: 'card-hit-defer',
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
                            debugLabel: 'card-hit-defer-top',
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
                            onSizeChanged: (s) =>
                                setState(() => _panelSize = s),
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
                            onWidthChanged: (w) =>
                                setState(() => _windowWidth = w),
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
                        _DemoTile(
                          title: 'Safe triangle',
                          body: _useHit
                              ? 'Hover a ▶ row, then cut diagonally into the '
                                    'submenu — the triangle protects the path. '
                                    'Linger on another ▶ to switch. Click away '
                                    'to close (menus stay open if you leave).'
                              : 'Same hover menu without the safe triangle — '
                                    'crossing other rows steals the submenu.',
                          footer: _lastMenuPick == null
                              ? 'No pick yet'
                              : 'Last: $_lastMenuPick',
                          child: _CascadingMenuDemo(
                            useHit: _useHit,
                            showHitArea: _showHitArea,
                            onPick: (label) =>
                                setState(() => _lastMenuPick = label),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
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
