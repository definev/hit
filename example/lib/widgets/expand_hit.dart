part of '../main.dart';

/// Shared HitLayer / plain-Flutter control used by several demos.
class _ExpandHit extends StatelessWidget {
  const _ExpandHit({
    required this.useHit,
    required this.showHitArea,
    required this.paintChild,
    this.debugLabel,
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
  final String? debugLabel;
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
      debugLabel: debugLabel,
      alignment: alignment,
      behavior: HitTestBehavior.deferToChild,
      hitChild: interact(
        child: SizedBox(width: hitSize.width, height: hitSize.height),
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
