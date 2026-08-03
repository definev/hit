import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';

/// Ancestor that hit-tests (and optionally paints) [Hit.defer] / [Hit.before]
/// targets outside normal parent bounds.
class HitScope extends StatefulWidget {
  const HitScope({super.key, required this.child, this.link});

  final Widget child;
  final HitLink? link;

  static HitScopeState of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedHitScope>();
    assert(inherited != null, 'HitScope was not found above this context.');
    return inherited!.state;
  }

  /// Returns null if there is no enclosing [HitScope].
  static HitScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedHitScope>()
        ?.state;
  }

  @override
  State<HitScope> createState() => HitScopeState();
}

class HitScopeState extends State<HitScope> {
  final HitLink _internalLink = HitLink();

  HitLink get link => widget.link ?? _internalLink;

  @override
  void didUpdateWidget(covariant HitScope oldWidget) {
    if (widget.link != null) {
      _internalLink.removeAll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _internalLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedHitScope(
      state: this,
      child: _HitScopeRenderObjectWidget(link: link, child: widget.child),
    );
  }
}

class _InheritedHitScope extends InheritedWidget {
  const _InheritedHitScope({required this.state, required super.child});

  final HitScopeState state;

  @override
  bool updateShouldNotify(_InheritedHitScope oldWidget) => false;
}

class _HitScopeRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _HitScopeRenderObjectWidget({required this.link, required super.child});

  final HitLink link;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHitScope(link);
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitScope renderObject) {
    renderObject.link = link;
  }
}

class RenderHitScope extends RenderProxyBox {
  RenderHitScope(HitLink link, [RenderBox? child]) : super(child) {
    this.link = link;
  }

  HitLink? _link;
  HitLink get link => _link!;
  set link(HitLink value) {
    if (_link != null) {
      _link!.removeListener(_onLinkChanged);
    }
    _link = value;
    _link!.addListener(_onLinkChanged);
    _clearAabbCache();
    markNeedsPaint();
  }

  /// Axis-aligned hit bounds in this scope's coordinates for the current
  /// [hitTest] pass only.
  ///
  /// Must not outlive a pass: scrolling updates child transforms without
  /// laying out this scope, so a cross-frame cache would reject valid hits.
  final Map<HitDeferRegistration, Rect> _aabbCache =
      <HitDeferRegistration, Rect>{};

  /// Retained follower layers for [Hit.defer] `paintOnTop` targets.
  ///
  /// Must use [LayerHandle] so layers stay alive after being detached from the
  /// previous frame's layer tree (a bare map lets `_parentHandle` dispose them).
  final Map<HitDeferRegistration, LayerHandle<FollowerLayer>> _followerHandles =
      <HitDeferRegistration, LayerHandle<FollowerLayer>>{};

  void _clearAabbCache() => _aabbCache.clear();

  void _onLinkChanged() {
    _clearAabbCache();
    markNeedsPaint();
  }

  @override
  void performLayout() {
    _clearAabbCache();
    super.performLayout();
  }

  void _releaseFollowerHandles() {
    for (final LayerHandle<FollowerLayer> handle in _followerHandles.values) {
      handle.layer = null;
    }
    _followerHandles.clear();
  }

  @override
  void dispose() {
    _link?.removeListener(_onLinkChanged);
    _releaseFollowerHandles();
    super.dispose();
  }

  bool _hitTestDeferredTarget(
    BoxHitTestResult result,
    Offset position,
    HitDeferRegistration target,
  ) {
    final Rect? cached = _aabbCache[target];
    if (cached != null && !cached.contains(position)) {
      return false;
    }

    final Matrix4 transform = target.hitTestBox.getTransformTo(this);
    final Rect aabb = MatrixUtils.transformRect(
      transform,
      target.deferredHitBounds,
    );
    _aabbCache[target] = aabb;
    if (!aabb.contains(position)) {
      return false;
    }

    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset? transformed) {
        return target.hitTestDeferred(result, transformed!);
      },
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Scroll / transform changes skip [performLayout] on this scope.
    _clearAabbCache();

    var anyDeferredHit = false;

    final bool opaqueHit = link.anyReversed((HitDeferRegistration target) {
      final hit = _hitTestDeferredTarget(result, position, target);
      anyDeferredHit = anyDeferredHit || hit;
      return hit && target.hitBehavior == HitTestBehavior.opaque;
    });

    if (opaqueHit) {
      return true;
    }

    final subtreeHit = child?.hitTest(result, position: position) ?? false;
    return anyDeferredHit || subtreeHit;
  }

  void _paintDeferredUnder(PaintingContext context, Offset offset) {
    link.forEach((HitDeferRegistration target) {
      if (!target.deferPaintUnder) {
        return;
      }
      final RenderBox? deferChild = target.registeredChild;
      if (deferChild == null) {
        return;
      }
      context.paintChild(
        deferChild,
        deferChild.localToGlobal(Offset.zero, ancestor: this) + offset,
      );
    });
  }

  void _paintDeferredOnTop(PaintingContext context, Offset offset) {
    final Set<HitDeferRegistration> painted = <HitDeferRegistration>{};

    link.forEach((HitDeferRegistration target) {
      if (!target.deferPaintOnTop) {
        return;
      }
      final LayerLink? paintLink = target.deferredPaintLink;
      final RenderBox? deferChild = target.registeredChild;
      if (paintLink == null || deferChild == null) {
        return;
      }
      painted.add(target);

      final LayerHandle<FollowerLayer> handle = _followerHandles.putIfAbsent(
        target,
        () => LayerHandle<FollowerLayer>(),
      );
      FollowerLayer? follower = handle.layer;
      if (follower == null) {
        follower = FollowerLayer(
          link: paintLink,
          showWhenUnlinked: false,
          linkedOffset: Offset.zero,
          unlinkedOffset: offset,
        );
        handle.layer = follower;
      } else {
        follower
          ..link = paintLink
          ..showWhenUnlinked = false
          ..linkedOffset = Offset.zero
          ..unlinkedOffset = offset;
      }

      context.pushLayer(
        follower,
        (PaintingContext context, Offset offset) {
          context.paintChild(deferChild, offset);
        },
        Offset.zero,
        childPaintBounds: const Rect.fromLTRB(
          double.negativeInfinity,
          double.negativeInfinity,
          double.infinity,
          double.infinity,
        ),
      );
    });

    _followerHandles.removeWhere(
        (HitDeferRegistration target, LayerHandle<FollowerLayer> handle) {
      if (painted.contains(target)) {
        return false;
      }
      handle.layer = null;
      return true;
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDeferredUnder(context, offset);
    super.paint(context, offset);
    _paintDeferredOnTop(context, offset);
  }
}
