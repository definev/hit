part of '../main.dart';

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
            debugLabel: 'slivers-inbox-list',
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
            debugLabel: 'slivers-icon-grid',
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
            debugLabel: 'sliver-inbox-trash-$index',
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
              debugLabel: 'sliver-grid-icon-$index',
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: const SizedBox(width: 48, height: 48),
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
