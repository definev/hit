import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';

/// Ancestor that hit-tests (and optionally paints) deferred targets outside
/// normal parent bounds.
///
/// Targets register via [Hit.defer], [Hit.before], or an overflowing
/// [HitLayer]. Nesting is supported; [of] / [maybeOf] resolve to the nearest
/// enclosing scope. Prefer many small scopes around overflow regions over one
/// app-wide scope.
///
/// Pass an explicit [link] to share a registry or to let descendants register
/// with this scope instead of a nearer one. Changing [link] at runtime
/// notifies dependents so deferred targets re-register on the new link.
///
/// Intermediate parents above this widget (`ClipRect`, tight boxes that reject
/// outside hits) can still block the hit-test walk even though
/// HitScope itself does not clip deferred hits to its size.
class HitScope extends StatefulWidget {
  /// Creates a scope that delivers deferred hits for [child]'s subtree.
  const HitScope({super.key, required this.child, this.link});

  /// The subtree that may contain deferred hit targets.
  final Widget child;

  /// Optional shared registry. When null, an internal [HitLink] is used.
  final HitLink? link;

  /// The nearest enclosing [HitScopeState].
  ///
  /// Throws a [FlutterError] if there is no enclosing [HitScope].
  ///
  /// See also:
  ///
  ///  * [maybeOf], which returns null instead of throwing.
  static HitScopeState of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedHitScope>();
    if (inherited == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'HitScope.of() called with a context that does not contain a HitScope.',
        ),
        ErrorDescription(
          'No HitScope ancestor could be found starting from the context '
          'that was passed to HitScope.of().',
        ),
        ErrorHint(
          'Hit.defer / Hit.before and overflowing HitLayer widgets require a '
          'HitScope ancestor whose layout box covers the deferred hit area.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return inherited.state;
  }

  /// The nearest enclosing [HitScopeState], or null if none exists.
  ///
  /// Prefer this over [of] when a missing scope is an allowed state.
  static HitScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedHitScope>()
        ?.state;
  }

  @override
  State<HitScope> createState() => HitScopeState();
}

/// State for a [HitScope].
///
/// Exposes [link] so descendants (and callers of [HitScope.of]) can register
/// deferred targets on this scope's registry.
class HitScopeState extends State<HitScope> {
  HitLink? _internalLink;

  /// The [HitLink] used by this scope.
  ///
  /// Returns [HitScope.link] when provided, otherwise an internal link owned
  /// by this state (created lazily on first access).
  HitLink get link => widget.link ?? (_internalLink ??= HitLink());

  @override
  void didUpdateWidget(covariant HitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drop registrations left on the internal link when switching to an
    // explicit one. Descendants re-register via inherited notify.
    if (oldWidget.link == null && widget.link != null) {
      _internalLink?.removeAll();
    }
  }

  @override
  void dispose() {
    _internalLink?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HitLink resolved = link;
    return _InheritedHitScope(
      state: this,
      link: resolved,
      child: _HitScopeRenderObjectWidget(link: resolved, child: widget.child),
    );
  }
}

class _InheritedHitScope extends InheritedWidget {
  const _InheritedHitScope({
    required this.state,
    required this.link,
    required super.child,
  });

  final HitScopeState state;
  final HitLink link;

  @override
  bool updateShouldNotify(_InheritedHitScope oldWidget) =>
      !identical(oldWidget.link, link);
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

/// Render object that performs deferred hit testing and optional deferred
/// paint for targets registered on [link].
///
/// Hit order: deferred targets newest-first, then the child subtree. An
/// opaque deferred hit stops further deferred scanning but still allows the
/// walk to return without testing remaining deferred targets.
///
/// Paint order: [Hit.before] targets, then the child, then [Hit.defer]
/// `paintOnTop` targets (via retained [FollowerLayer]s).
class RenderHitScope extends RenderProxyBox {
  /// Creates a scope render object bound to [link].
  RenderHitScope(HitLink link, [RenderBox? child]) : super(child) {
    this.link = link;
  }

  HitLink? _link;

  /// Registry of deferred targets hit-tested and painted by this scope.
  HitLink get link => _link!;
  set link(HitLink value) {
    if (identical(_link, value)) {
      return;
    }
    if (_link != null) {
      _link!.removeListener(_onLinkChanged);
    }
    _link = value;
    _link!.addListener(_onLinkChanged);
    markNeedsPaint();
  }

  /// Retained follower layers for [Hit.defer] `paintOnTop` targets.
  ///
  /// Must use [LayerHandle] so layers stay alive after being detached from the
  /// previous frame's layer tree (a bare map lets `_parentHandle` dispose them).
  final Map<HitDeferRegistration, LayerHandle<FollowerLayer>> _followerHandles =
      <HitDeferRegistration, LayerHandle<FollowerLayer>>{};

  void _onLinkChanged() {
    markNeedsPaint();
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
    // Recompute each pass: scrolling updates child transforms without laying
    // out this scope, so a cross-frame AABB cache would reject valid hits.
    final Matrix4 transform = target.hitTestBox.getTransformTo(this);
    final Rect aabb = MatrixUtils.transformRect(
      transform,
      target.deferredHitBounds,
    );
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

  /// Hit-tests deferred targets (newest first), then the scoped subtree.
  ///
  /// When a deferred target with [HitTestBehavior.opaque] hits, scanning
  /// stops and the scoped subtree is **not** hit-tested.
  ///
  /// [HitTestBehavior.translucent] deferred hits still allow the subtree walk.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
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
