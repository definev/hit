part of '../main.dart';

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
                    debugLabel: 'window-edge',
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
