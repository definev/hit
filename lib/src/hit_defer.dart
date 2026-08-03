import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';
import 'hit_scope.dart';

/// Entry points for widgets whose hit testing (and optionally paint) is
/// deferred to an ancestor [HitScope].
///
/// Use these when a child sits outside its parent's layout box (for example a
/// [Positioned] badge that overflows a [Stack]) and must still receive pointer
/// events. Local [RenderBox.hitTest] always returns `false`; delivery happens
/// only through the enclosing [HitScope].
///
/// See also:
///
///  * [HitLayer], for separating paint/layout size from hit size in place.
///  * [HitScope], the ancestor that performs deferred hit testing and paint.
abstract final class Hit {
  const Hit._();

  /// Defers hit testing of [child] to the nearest [HitScope].
  ///
  /// By default the child paints in place. Set [paintOnTop] to paint after the
  /// scoped subtree via a composited [LeaderLayer] / [FollowerLayer] pair so
  /// paint tracks scroll and transforms without forcing the scope to repaint
  /// every frame.
  ///
  /// [link] defaults to [HitScope.of]'s link. Pass an explicit [HitLink] to
  /// register with a non-nearest scope.
  ///
  /// [behavior] controls how this target interacts with other deferred targets
  /// during the scope's hit walk ([HitTestBehavior.opaque] stops further
  /// deferred scanning after a hit).
  static Widget defer({
    Key? key,
    required Widget child,
    bool paintOnTop = false,
    HitLink? link,
    HitTestBehavior behavior = HitTestBehavior.translucent,
  }) {
    return _HitDeferWidget(
      key: key,
      paintOnTop: paintOnTop,
      paintUnder: false,
      link: link,
      behavior: behavior,
      child: child,
    );
  }

  /// Defers hit testing of [child] and paints it under the [HitScope] subtree.
  ///
  /// Paint is performed by [RenderHitScope] using
  /// [RenderBox.localToGlobal], so the child does not paint at its local
  /// position. Hit delivery is the same as [defer].
  ///
  /// [link] and [behavior] have the same meaning as in [defer].
  static Widget before({
    Key? key,
    required Widget child,
    HitLink? link,
    HitTestBehavior behavior = HitTestBehavior.translucent,
  }) {
    return _HitDeferWidget(
      key: key,
      paintOnTop: false,
      paintUnder: true,
      link: link,
      behavior: behavior,
      child: child,
    );
  }
}

class _HitDeferWidget extends StatelessWidget {
  const _HitDeferWidget({
    super.key,
    required this.child,
    required this.paintOnTop,
    required this.paintUnder,
    required this.behavior,
    this.link,
  });

  final Widget child;
  final bool paintOnTop;
  final bool paintUnder;
  final HitLink? link;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    final HitLink resolvedLink = link ?? HitScope.of(context).link;
    return _HitDeferRenderObjectWidget(
      link: resolvedLink,
      paintOnTop: paintOnTop,
      paintUnder: paintUnder,
      behavior: behavior,
      child: child,
    );
  }
}

class _HitDeferRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _HitDeferRenderObjectWidget({
    required this.link,
    required this.paintOnTop,
    required this.paintUnder,
    required this.behavior,
    required super.child,
  });

  final HitLink link;
  final bool paintOnTop;
  final bool paintUnder;
  final HitTestBehavior behavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHitDefer(
      link: link,
      paintOnTop: paintOnTop,
      paintUnder: paintUnder,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitDefer renderObject) {
    renderObject
      ..link = link
      ..deferPaintOnTop = paintOnTop
      ..deferPaintUnder = paintUnder
      ..hitBehavior = behavior;
  }
}

/// Render object for [Hit.defer] / [Hit.before].
///
/// Registers on [link] while attached, skips local hit testing, and optionally
/// defers paint to [RenderHitScope] when [deferPaintOnTop] or [deferPaintUnder]
/// is set.
class RenderHitDefer extends RenderProxyBox implements HitDeferRegistration {
  /// Creates a deferred hit target bound to [link].
  RenderHitDefer({
    required HitLink link,
    required bool paintOnTop,
    required bool paintUnder,
    required HitTestBehavior behavior,
    RenderBox? child,
  })  : _link = link,
        _paintOnTop = paintOnTop,
        _paintUnder = paintUnder,
        _behavior = behavior,
        super(child);

  HitLink _link;

  /// Registry this target is registered with while attached.
  HitLink get link => _link;

  set link(HitLink value) {
    if (identical(_link, value)) {
      return;
    }
    if (attached) {
      _link.remove(this);
    }
    _link = value;
    if (attached) {
      _link.add(this);
    }
  }

  /// Tracks this target for [HitScope]'s composited paintOnTop follower.
  final LayerLink _paintLink = LayerLink();

  bool _paintOnTop;

  /// Whether [HitScope] should paint this child after the scoped subtree.
  @override
  bool get deferPaintOnTop => _paintOnTop;
  set deferPaintOnTop(bool value) {
    if (_paintOnTop == value) {
      return;
    }
    _paintOnTop = value;
    markNeedsPaint();
  }

  bool _paintUnder;

  /// Whether [HitScope] should paint this child under the scoped subtree.
  @override
  bool get deferPaintUnder => _paintUnder;
  set deferPaintUnder(bool value) {
    if (_paintUnder == value) {
      return;
    }
    _paintUnder = value;
    markNeedsPaint();
  }

  HitTestBehavior _behavior;

  /// How this target participates in the [HitScope] deferred hit walk.
  @override
  HitTestBehavior get hitBehavior => _behavior;
  set hitBehavior(HitTestBehavior value) {
    _behavior = value;
  }

  @override
  RenderBox? get registeredChild => child;

  @override
  RenderBox get hitTestBox => child!;

  @override
  LayerLink? get deferredPaintLink => _paintOnTop ? _paintLink : null;

  @override
  Rect get deferredHitBounds {
    final RenderBox? c = child;
    if (c == null) {
      return Rect.zero;
    }
    return Offset.zero & c.size;
  }

  @override
  bool hitTestDeferred(BoxHitTestResult result, Offset position) {
    return child!.hitTest(result, position: position);
  }

  Size? _lastChildSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size? next = child?.size;
    if (_paintOnTop) {
      _paintLink.leaderSize = next;
    }
    if (attached && child != null && _lastChildSize != next) {
      _lastChildSize = next;
      if (_link.contains(this)) {
        _link.markGeometryDirty();
      }
    }
  }

  @override
  set child(RenderBox? value) {
    if (attached) {
      _link.remove(this);
    }
    super.child = value;
    _lastChildSize = null;
    if (value != null && attached) {
      _link.add(this);
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _link.add(this);
  }

  @override
  void detach() {
    _link.remove(this);
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing =>
      _paintOnTop || super.alwaysNeedsCompositing;

  /// Always returns `false`; hits are delivered only via [HitScope].
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_paintOnTop) {
      // Leader updates with scroll / transforms; HitScope paints via FollowerLayer.
      if (child != null) {
        final LeaderLayer leaderLayer = layer is LeaderLayer
            ? layer! as LeaderLayer
            : LeaderLayer(link: _paintLink);
        layer = leaderLayer
          ..link = _paintLink
          ..offset = offset;
        context.pushLayer(leaderLayer,
            (PaintingContext context, Offset offset) {}, Offset.zero);
      }
      return;
    }
    if (_paintUnder) {
      // Painted under the scope subtree via [RenderHitScope] (localToGlobal).
      return;
    }
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  void markNeedsPaint() {
    if (_paintUnder && !_paintOnTop) {
      _link.descendantNeedsPaint();
    } else {
      super.markNeedsPaint();
      if (_paintOnTop) {
        // Follower lives on the scope; keep it in sync when leader first appears.
        _link.descendantNeedsPaint();
      }
    }
  }
}
