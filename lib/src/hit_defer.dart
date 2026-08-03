import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';
import 'hit_scope.dart';

/// Deferred hit targets registered with an ancestor [HitScope].
abstract final class Hit {
  const Hit._();

  /// Defers hit testing to the nearest [HitScope]. Use [paintOnTop] to paint
  /// after the scoped subtree.
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

  /// Defers hit testing and paints under the [HitScope] subtree.
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

class RenderHitDefer extends RenderProxyBox implements HitDeferRegistration {
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
