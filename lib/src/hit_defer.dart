import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_debug.dart';
import 'hit_devtools.dart';
import 'hit_link.dart';
import 'hit_scope.dart';

/// Defers hit testing (and optionally paint) of [child] to an ancestor
/// [HitScope].
///
/// Use when a child sits outside its parent's layout box (for example a
/// [Positioned] badge that overflows a [Stack]) and must still receive pointer
/// events. Local [RenderBox.hitTest] always returns `false`; delivery happens
/// only through the enclosing [HitScope].
///
/// By default ([HitDeferPaint.none]) the child paints in place. Set [paint]
/// to [HitDeferPaint.onTop] to paint after the scoped subtree via a
/// composited [LeaderLayer] / [FollowerLayer] pair so paint tracks scroll
/// and transforms without forcing the scope to repaint every frame.
///
/// [link] defaults to [HitScope.of]'s link. Pass an explicit [HitLink] to
/// register with a non-nearest scope.
///
/// [behavior] defaults to [HitTestBehavior.translucent]. During the scope's
/// newest-first deferred walk, [HitTestBehavior.opaque] stops further
/// deferred scanning **and** skips hit-testing the scoped subtree.
/// [HitTestBehavior.translucent] still allows the subtree walk after a hit.
///
/// See also:
///
///  * [HitLayer], for separating paint/layout size from hit size in place.
///  * [HitScope], the ancestor that performs deferred hit testing and paint.
class HitDefer extends StatelessWidget {
  /// Creates a deferred hit target.
  const HitDefer({
    super.key,
    required this.child,
    this.paint = HitDeferPaint.none,
    this.link,
    this.behavior = HitTestBehavior.translucent,
    this.debugLabel,
  });

  /// The widget whose hit testing (and optionally paint) is deferred.
  final Widget child;

  /// How [HitScope] paints [child] relative to the scoped subtree.
  final HitDeferPaint paint;

  /// Registry to register with. Defaults to the nearest [HitScope]'s link.
  final HitLink? link;

  /// How this target participates in the [HitScope] deferred hit walk.
  final HitTestBehavior behavior;

  /// Optional name for DevTools / Flutter Inspector (debug builds).
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    assert(() {
      ensureHitDevToolsInitialized();
      return true;
    }());
    final HitLink resolvedLink = link ?? HitScope.of(context).link;
    return _HitDeferRenderObjectWidget(
      link: resolvedLink,
      paint: paint,
      behavior: behavior,
      debugLabel: debugLabel,
      child: child,
    );
  }
}

class _HitDeferRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _HitDeferRenderObjectWidget({
    required this.link,
    required this.paint,
    required this.behavior,
    required this.debugLabel,
    required super.child,
  });

  final HitLink link;
  final HitDeferPaint paint;
  final HitTestBehavior behavior;
  final String? debugLabel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHitDefer(
      link: link,
      paint: paint,
      behavior: behavior,
      debugLabel: debugLabel,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitDefer renderObject) {
    renderObject
      ..link = link
      ..deferPaint = paint
      ..hitBehavior = behavior
      ..debugLabel = debugLabel;
  }
}

/// Render object for [HitDefer].
///
/// Registers on [link] while attached, skips local hit testing, and optionally
/// defers paint to the enclosing [HitScope] when [deferPaint] is not
/// [HitDeferPaint.none].
class RenderHitDefer extends RenderProxyBox
    with HitDebugPaintMixin
    implements HitDeferRegistration {
  /// Creates a deferred hit target bound to [link].
  RenderHitDefer({
    required HitLink link,
    required HitDeferPaint paint,
    required HitTestBehavior behavior,
    String? debugLabel,
    RenderBox? child,
  })  : _link = link,
        _paint = paint,
        _behavior = behavior,
        _debugLabel = debugLabel,
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

  String? _debugLabel;

  /// Optional name for DevTools / Flutter Inspector.
  @override
  String? get debugLabel => _debugLabel;
  set debugLabel(String? value) {
    if (_debugLabel == value) {
      return;
    }
    _debugLabel = value;
  }

  /// Tracks this target for [HitScope]'s composited [HitDeferPaint.onTop]
  /// follower.
  final LayerLink _paintLink = LayerLink();

  HitDeferPaint _paint;

  /// How [HitScope] paints this child relative to the scoped subtree.
  @override
  HitDeferPaint get deferPaint => _paint;
  set deferPaint(HitDeferPaint value) {
    if (_paint == value) {
      return;
    }
    _paint = value;
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
  RenderBox get hitTestBox => this;

  @override
  Rect get deferredHitBounds => Offset.zero & size;

  @override
  LayerLink? get deferredPaintLink =>
      _paint == HitDeferPaint.onTop ? _paintLink : null;

  @override
  LayerLink? get hitDebugLeaderLink =>
      // Always null when asserts are disabled (release / profile).
      hitDebugPaintingEnabled ? _paintLink : null;

  bool get _needsDebugLeader =>
      hitDebugPaintingEnabled && _paint == HitDeferPaint.none;

  @override
  bool hitTestDeferred(BoxHitTestResult result, Offset position) {
    final RenderBox? c = child;
    if (c == null) {
      return false;
    }
    return c.hitTest(result, position: position);
  }

  Size? _lastChildSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size? next = child?.size;
    if (_paint == HitDeferPaint.onTop) {
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
    attachHitDebugPaintListener();
    _link.add(this);
  }

  @override
  void detach() {
    detachHitDebugPaintListener();
    _link.remove(this);
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing =>
      _paint == HitDeferPaint.onTop ||
      _needsDebugLeader ||
      super.alwaysNeedsCompositing;

  /// Always returns `false`; hits are delivered only via [HitScope].
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    switch (_paint) {
      case HitDeferPaint.onTop:
        // Leader updates with scroll / transforms; HitScope paints via
        // FollowerLayer. The same leader anchors the debug overlay follower.
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
      case HitDeferPaint.none:
        if (child == null) {
          layer = null;
          return;
        }
        if (_needsDebugLeader) {
          // Establish a leader so HitScope's debug follower tracks this child
          // through scroll / transforms.
          final LeaderLayer leaderLayer = layer is LeaderLayer
              ? layer! as LeaderLayer
              : LeaderLayer(link: _paintLink);
          layer = leaderLayer
            ..link = _paintLink
            ..offset = offset;
          context.pushLayer(
            leaderLayer,
            (PaintingContext context, Offset offset) {
              context.paintChild(child!, offset);
            },
            Offset.zero,
          );
        } else {
          layer = null;
          context.paintChild(child!, offset);
        }
    }
  }

  @override
  void markNeedsPaint() {
    switch (_paint) {
      case HitDeferPaint.onTop:
        super.markNeedsPaint();
        // Follower lives on the scope; keep it in sync when leader first
        // appears.
        _link.descendantNeedsPaint();
      case HitDeferPaint.none:
        super.markNeedsPaint();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('debugLabel', debugLabel, defaultValue: null),
    );
  }
}
