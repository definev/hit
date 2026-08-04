part of 'main.dart';

class _ToolbarToggle extends StatelessWidget {
  const _ToolbarToggle({
    required this.tooltip,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final String tooltip;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color on = activeColor ?? colors.primary;
    return DevToolsTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () => onChanged(!value),
        icon: Icon(
          icon,
          size: 18,
          color: value ? on : colors.onSurfaceVariant,
        ),
        style: IconButton.styleFrom(
          backgroundColor: value ? on.withValues(alpha: 0.14) : null,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final Widget? actions;

  /// Matches compact IconButton toolbar height so tree/details headers align.
  static const double _headerHeight = 40;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            defaultSpacing,
            0,
            denseSpacing,
            0,
          ),
          child: SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (actions != null) actions!,
              ],
            ),
          ),
        ),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(defaultSpacing),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

/// 1px paint divider with an expanded [HitLayer] grab strip.
///
/// [Axis.horizontal] separates left/right panes (horizontal drag).
/// [Axis.vertical] separates top/bottom panes (vertical drag).
class _PaneResizeHandle extends StatelessWidget {
  const _PaneResizeHandle({
    required this.onDrag,
    this.axis = Axis.horizontal,
  });

  final ValueChanged<double> onDrag;
  final Axis axis;

  static const double _paintThickness = 1;
  static const double _hitThickness = 12;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool horizontal = axis == Axis.horizontal;
    // HitLayer lays out [hitChild] with loosened constraints, so the cross-axis
    // size must be explicit — a single-axis SizedBox collapses to 0.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size hitSize = horizontal
            ? Size(_hitThickness, constraints.maxHeight)
            : Size(constraints.maxWidth, _hitThickness);
        final Size paintSize = horizontal
            ? Size(_paintThickness, constraints.maxHeight)
            : Size(constraints.maxWidth, _paintThickness);
        return HitLayer(
          debugLabel: horizontal ? 'pane-resize-h' : 'pane-resize-v',
          alignment: Alignment.center,
          hitChild: MouseRegion(
            cursor: horizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: horizontal
                  ? (DragUpdateDetails details) => onDrag(details.delta.dx)
                  : null,
              onVerticalDragUpdate: horizontal
                  ? null
                  : (DragUpdateDetails details) => onDrag(details.delta.dy),
              child: SizedBox.fromSize(size: hitSize),
            ),
          ),
          // Ignore so paint hits don't swallow the drag detector.
          paintChild: IgnorePointer(
            child: ColoredBox(
              color: colors.outlineVariant,
              child: SizedBox.fromSize(size: paintSize),
            ),
          ),
        );
      },
    );
  }
}
