part of '../main.dart';

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
                    debugLabel: 'resize-handle',
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
