part of '../main.dart';

/// Hover a media card → floating toolbar hangs *above* the card.
///
/// Uses a Cupertino-style elevated pill ([CupertinoPopupSurface] + shadow)
/// and [CupertinoButton]. The toolbar sits outside the card [SizedBox], so
/// without [HitDefer] those taps miss.
///
/// [MouseRegion] must wrap [HitScope] (not sit inside it). An opaque deferred
/// hit skips the scoped subtree — if the region lived inside, hover would
/// exit/re-enter in a loop whenever the pointer was over the bar.
class _HoverToolbar extends StatefulWidget {
  const _HoverToolbar({
    required this.useHit,
    required this.showHitArea,
    required this.onAction,
  });

  final bool useHit;
  final bool showHitArea;
  final ValueChanged<String> onAction;

  @override
  State<_HoverToolbar> createState() => _HoverToolbarState();
}

class _HoverToolbarState extends State<_HoverToolbar> {
  bool _hovered = false;

  static const double _overhang = 44;
  static const double _cardHeight = 112;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final label = CupertinoColors.label.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);
    final destructive = CupertinoColors.destructiveRed.resolveFrom(context);

    Widget toolbar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 0.5,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CupertinoPopupSurface(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: separator.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CupertinoHitIconButton(
                    useHit: widget.useHit,
                    showHitArea: widget.showHitArea,
                    debugLabel: 'toolbar-crop',
                    icon: CupertinoIcons.crop,
                    color: label,
                    onPressed: () => widget.onAction('Crop'),
                  ),
                  _ToolbarDivider(color: separator),
                  _CupertinoHitIconButton(
                    useHit: widget.useHit,
                    showHitArea: widget.showHitArea,
                    debugLabel: 'toolbar-link',
                    icon: CupertinoIcons.link,
                    color: primary,
                    onPressed: () => widget.onAction('Link'),
                  ),
                  _ToolbarDivider(color: separator),
                  _CupertinoHitIconButton(
                    useHit: widget.useHit,
                    showHitArea: widget.showHitArea,
                    debugLabel: 'toolbar-trash',
                    icon: CupertinoIcons.trash,
                    color: destructive,
                    onPressed: () => widget.onAction('Delete'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Keep hit-testable while visible; hide only visually when not hovered.
    toolbar = IgnorePointer(
      ignoring: !_hovered,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        offset: _hovered ? Offset.zero : const Offset(0, 0.18),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          opacity: _hovered ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            scale: _hovered ? 1 : 0.92,
            child: toolbar,
          ),
        ),
      ),
    );

    if (widget.useHit) {
      // Translucent: deferred hit must not block HitScope's subtree walk for
      // other targets; MouseRegion lives *above* the scope either way.
      toolbar = HitDefer(
        debugLabel: 'hover-toolbar',
        paint: HitDeferPaint.none,
        behavior: HitTestBehavior.translucent,
        child: toolbar,
      );
    } else if (widget.showHitArea) {
      toolbar = Stack(
        children: [
          toolbar,
          const Positioned.fill(child: IgnorePointer(child: _HitGhost())),
        ],
      );
    }

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: HitScope(
        debugLabel: 'hover-toolbar-scope',
        child: SizedBox(
          width: double.infinity,
          height: _cardHeight + _overhang,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: _overhang,
                bottom: 0,
                child: SizedBox(
                  height: _cardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: _HoverToolbarCard(primary: primary),
                      ),
                      Positioned(
                        top: -_overhang + 6,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: toolbar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 18,
        width: 1,
        child: ColoredBox(color: color.withValues(alpha: 0.65)),
      ),
    );
  }
}

/// Photo-card stand-in — stronger gradient so the floating bar has contrast.
class _HoverToolbarCard extends StatelessWidget {
  const _HoverToolbarCard({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 1),
                    primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CupertinoColors.white.withValues(alpha: 0.18),
                  const Color(0x00000000),
                  CupertinoColors.black.withValues(alpha: 0.35),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CupertinoColors.separator.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact [CupertinoButton] whose hit expands via [HitLayer] when [useHit].
class _CupertinoHitIconButton extends StatelessWidget {
  const _CupertinoHitIconButton({
    required this.useHit,
    required this.showHitArea,
    required this.icon,
    required this.onPressed,
    this.debugLabel,
    this.color,
  });

  final bool useHit;
  final bool showHitArea;
  final IconData icon;
  final VoidCallback onPressed;
  final String? debugLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 18, color: color);

    if (!useHit) {
      return CupertinoButton(
        sizeStyle: CupertinoButtonSize.small,
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        onPressed: onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            iconWidget,
            if (showHitArea)
              const Positioned.fill(child: IgnorePointer(child: _HitGhost())),
          ],
        ),
      );
    }

    return _ExpandHit(
      useHit: true,
      showHitArea: showHitArea,
      debugLabel: debugLabel,
      onTap: onPressed,
      hitSize: const Size(44, 44),
      paintChild: CupertinoButton(
        sizeStyle: CupertinoButtonSize.small,
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        onPressed: () {},
        child: iconWidget,
      ),
    );
  }
}
