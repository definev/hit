part of '../main.dart';

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.useHit,
    required this.showHitArea,
    required this.paint,
    required this.onTap,
    this.debugLabel,
    this.cover = false,
  });

  final bool useHit;
  final bool showHitArea;
  final HitDeferPaint paint;
  final VoidCallback onTap;
  final String? debugLabel;
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
            // Manual overlay only for plain Flutter; HitDefer paints via
            // debugPaintHitAreas on the enclosing HitScope.
            if (!useHit && showHitArea)
              const IgnorePointer(child: _HitGhost(circular: true)),
          ],
        ),
      ),
    );

    if (useHit) {
      badge = switch (paint) {
        HitDeferPaint.onTop => HitDefer(
          debugLabel: debugLabel,
          paint: HitDeferPaint.onTop,
          behavior: HitTestBehavior.opaque,
          child: badge,
        ),
        HitDeferPaint.none => HitDefer(
          debugLabel: debugLabel,
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
                  style: TextStyle(color: CupertinoColors.white, fontSize: 12),
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
