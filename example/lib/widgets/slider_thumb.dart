part of '../main.dart';

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
                  debugLabel: 'slider-thumb',
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
