import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';

/// Registry handle exposed by [HitScope] and [SliverHitScope].
///
/// [HitScope.of] / [HitScope.maybeOf] resolve to the nearest enclosing scope
/// of either kind.
abstract interface class HitScopeHandle {
  /// The [HitLink] used by this scope.
  HitLink get link;
}

/// Ancestor that hit-tests (and optionally paints) deferred targets outside
/// normal parent bounds.
///
/// Targets register via [Hit.defer], [Hit.before], or an overflowing
/// [HitLayer]. Nesting is supported; [of] / [maybeOf] resolve to the nearest
/// enclosing scope ([HitScope] or [SliverHitScope]). Prefer many small scopes
/// around overflow regions over one app-wide scope.
///
/// Pass an explicit [link] to share a registry or to let descendants register
/// with this scope instead of a nearer one. Changing [link] at runtime
/// notifies dependents so deferred targets re-register on the new link.
///
/// Intermediate parents above this widget (`ClipRect`, tight boxes that reject
/// outside hits) can still block the hit-test walk even though
/// HitScope itself does not clip deferred hits to its size.
///
/// For [CustomScrollView] / sliver trees, use [SliverHitScope] instead.
class HitScope extends StatefulWidget {
  /// Creates a scope that delivers deferred hits for [child]'s subtree.
  const HitScope({super.key, required this.child, this.link});

  /// The subtree that may contain deferred hit targets.
  final Widget child;

  /// Optional shared registry. When null, an internal [HitLink] is used.
  final HitLink? link;

  /// The nearest enclosing [HitScopeHandle] ([HitScope] or [SliverHitScope]).
  ///
  /// Throws a [FlutterError] if there is no enclosing scope.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which returns null instead of throwing.
  static HitScopeHandle of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedHitScope>();
    if (inherited == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'HitScope.of() called with a context that does not contain a HitScope.',
        ),
        ErrorDescription(
          'No HitScope or SliverHitScope ancestor could be found starting from '
          'the context that was passed to HitScope.of().',
        ),
        ErrorHint(
          'Hit.defer / Hit.before and overflowing HitLayer widgets require a '
          'HitScope or SliverHitScope ancestor whose layout covers the '
          'deferred hit area.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return inherited.handle;
  }

  /// The nearest enclosing [HitScopeHandle], or null if none exists.
  ///
  /// Prefer this over [of] when a missing scope is an allowed state.
  static HitScopeHandle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedHitScope>()
        ?.handle;
  }

  @override
  State<HitScope> createState() => HitScopeState();
}

/// State for a [HitScope].
///
/// Exposes [link] so descendants (and callers of [HitScope.of]) can register
/// deferred targets on this scope's registry.
class HitScopeState extends State<HitScope> implements HitScopeHandle {
  HitLink? _internalLink;

  /// The [HitLink] used by this scope.
  ///
  /// Returns [HitScope.link] when provided, otherwise an internal link owned
  /// by this state (created lazily on first access).
  @override
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
      handle: this,
      link: resolved,
      child: _HitScopeRenderObjectWidget(link: resolved, child: widget.child),
    );
  }
}

/// Sliver ancestor that hit-tests (and optionally paints) deferred targets
/// outside normal child bounds inside a [CustomScrollView] (or other viewport).
///
/// Same deferred contract as [HitScope]: targets register via [Hit.defer],
/// [Hit.before], or an overflowing [HitLayer]. [HitScope.of] / [maybeOf]
/// resolve to this scope when it is the nearest enclosing scope.
///
/// Place this in a `slivers` list (or as another sliver's child). Deferred
/// hits are only delivered while the pointer falls inside this sliver's
/// [SliverGeometry.hitTestExtent] and cross-axis extent — same coverage rule
/// as box [HitScope], applied to sliver geometry.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverHitScope(
///       sliver: SliverList.builder(
///         itemBuilder: (context, index) => /* HitLayer / Hit.defer */,
///       ),
///     ),
///   ],
/// )
/// ```
class SliverHitScope extends StatefulWidget {
  /// Creates a sliver scope that delivers deferred hits for [sliver]'s subtree.
  const SliverHitScope({super.key, required this.sliver, this.link});

  /// The sliver subtree that may contain deferred hit targets.
  final Widget sliver;

  /// Optional shared registry. When null, an internal [HitLink] is used.
  final HitLink? link;

  @override
  State<SliverHitScope> createState() => SliverHitScopeState();
}

/// State for a [SliverHitScope].
///
/// Exposes [link] so descendants (and callers of [HitScope.of]) can register
/// deferred targets on this scope's registry.
class SliverHitScopeState extends State<SliverHitScope>
    implements HitScopeHandle {
  HitLink? _internalLink;

  /// The [HitLink] used by this scope.
  ///
  /// Returns [SliverHitScope.link] when provided, otherwise an internal link
  /// owned by this state (created lazily on first access).
  @override
  HitLink get link => widget.link ?? (_internalLink ??= HitLink());

  @override
  void didUpdateWidget(covariant SliverHitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      handle: this,
      link: resolved,
      child: _SliverHitScopeRenderObjectWidget(
        link: resolved,
        child: widget.sliver,
      ),
    );
  }
}

class _InheritedHitScope extends InheritedWidget {
  const _InheritedHitScope({
    required this.handle,
    required this.link,
    required super.child,
  });

  final HitScopeHandle handle;
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

class _SliverHitScopeRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _SliverHitScopeRenderObjectWidget({
    required this.link,
    required Widget child,
  }) : super(child: child);

  final HitLink link;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSliverHitScope(link);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverHitScope renderObject,
  ) {
    renderObject.link = link;
  }
}

/// Shared deferred hit / paint behavior for box and sliver hit scopes.
mixin _HitScopeDeferredMixin on RenderObject {
  HitLink get link;

  final Map<HitDeferRegistration, LayerHandle<FollowerLayer>> _followerHandles =
      <HitDeferRegistration, LayerHandle<FollowerLayer>>{};

  void _attachLink(HitLink? oldLink, HitLink newLink) {
    if (identical(oldLink, newLink)) {
      return;
    }
    oldLink?.removeListener(_onLinkChanged);
    newLink.addListener(_onLinkChanged);
    markNeedsPaint();
  }

  void _detachLink(HitLink? link) {
    link?.removeListener(_onLinkChanged);
  }

  void _onLinkChanged() {
    markNeedsPaint();
  }

  void _releaseFollowerHandles() {
    for (final LayerHandle<FollowerLayer> handle in _followerHandles.values) {
      handle.layer = null;
    }
    _followerHandles.clear();
  }

  bool hitTestDeferredTarget(
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

  /// Returns whether an opaque deferred target hit. [anyDeferredHit] is set
  /// when any deferred target hit (opaque or translucent).
  bool hitTestDeferredTargets(
    BoxHitTestResult result,
    Offset position,
    void Function(bool anyDeferredHit) reportAnyDeferredHit,
  ) {
    var anyDeferredHit = false;

    final bool opaqueHit = link.anyReversed((HitDeferRegistration target) {
      final hit = hitTestDeferredTarget(result, position, target);
      anyDeferredHit = anyDeferredHit || hit;
      return hit && target.hitBehavior == HitTestBehavior.opaque;
    });

    reportAnyDeferredHit(anyDeferredHit);
    return opaqueHit;
  }

  void paintDeferredUnder(PaintingContext context, Offset offset) {
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

  void paintDeferredOnTop(PaintingContext context, Offset offset) {
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

    _followerHandles.removeWhere((
      HitDeferRegistration target,
      LayerHandle<FollowerLayer> handle,
    ) {
      if (painted.contains(target)) {
        return false;
      }
      handle.layer = null;
      return true;
    });
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
class RenderHitScope extends RenderProxyBox with _HitScopeDeferredMixin {
  /// Creates a scope render object bound to [link].
  RenderHitScope(HitLink link, [RenderBox? child]) : super(child) {
    _link = link;
    link.addListener(_onLinkChanged);
  }

  HitLink? _link;

  /// Registry of deferred targets hit-tested and painted by this scope.
  @override
  HitLink get link => _link!;
  set link(HitLink value) {
    final HitLink? old = _link;
    if (identical(old, value)) {
      return;
    }
    _link = value;
    _attachLink(old, value);
  }

  @override
  void dispose() {
    _detachLink(_link);
    _releaseFollowerHandles();
    super.dispose();
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

    final bool opaqueHit = hitTestDeferredTargets(result, position, (hit) {
      anyDeferredHit = hit;
    });

    if (opaqueHit) {
      return true;
    }

    final subtreeHit = child?.hitTest(result, position: position) ?? false;
    return anyDeferredHit || subtreeHit;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintDeferredUnder(context, offset);
    super.paint(context, offset);
    paintDeferredOnTop(context, offset);
  }
}

/// Sliver render object that performs deferred hit testing and optional
/// deferred paint for targets registered on [link].
///
/// Same hit / paint order as [RenderHitScope], using sliver hit coordinates
/// converted into this sliver's paint space.
class RenderSliverHitScope extends RenderProxySliver
    with _HitScopeDeferredMixin {
  /// Creates a sliver scope render object bound to [link].
  RenderSliverHitScope(HitLink link, [RenderSliver? child]) : super(child) {
    _link = link;
    link.addListener(_onLinkChanged);
  }

  HitLink? _link;

  /// Registry of deferred targets hit-tested and painted by this scope.
  @override
  HitLink get link => _link!;
  set link(HitLink value) {
    final HitLink? old = _link;
    if (identical(old, value)) {
      return;
    }
    _link = value;
    _attachLink(old, value);
  }

  @override
  void dispose() {
    _detachLink(_link);
    _releaseFollowerHandles();
    super.dispose();
  }

  /// Converts sliver hit coordinates into this sliver's paint [Offset].
  ///
  /// Matches how viewports map pointer positions into sliver space for
  /// [AxisDirection.down] / [AxisDirection.right], and flips main-axis for
  /// reverse directions so the result aligns with [RenderObject.getTransformTo]
  /// paint transforms.
  Offset paintOffsetForHit({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    final AxisDirection direction = applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    );
    return switch (direction) {
      AxisDirection.down => Offset(crossAxisPosition, mainAxisPosition),
      AxisDirection.up => Offset(
          crossAxisPosition,
          geometry!.paintExtent - mainAxisPosition,
        ),
      AxisDirection.right => Offset(mainAxisPosition, crossAxisPosition),
      AxisDirection.left => Offset(
          geometry!.paintExtent - mainAxisPosition,
          crossAxisPosition,
        ),
    };
  }

  /// Hit-tests deferred targets (newest first), then the scoped sliver.
  ///
  /// When a deferred target with [HitTestBehavior.opaque] hits, scanning
  /// stops and the scoped sliver is **not** hit-tested.
  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (mainAxisPosition < 0.0 ||
        mainAxisPosition >= geometry!.hitTestExtent ||
        crossAxisPosition < 0.0 ||
        crossAxisPosition >= constraints.crossAxisExtent) {
      return false;
    }

    final Offset position = paintOffsetForHit(
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
    final BoxHitTestResult boxResult = BoxHitTestResult.wrap(result);

    var anyDeferredHit = false;
    final bool opaqueHit = hitTestDeferredTargets(boxResult, position, (hit) {
      anyDeferredHit = hit;
    });

    if (opaqueHit) {
      result.add(
        SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ),
      );
      return true;
    }

    final bool childHit = hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
    if (anyDeferredHit || childHit) {
      result.add(
        SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ),
      );
      return true;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintDeferredUnder(context, offset);
    super.paint(context, offset);
    paintDeferredOnTop(context, offset);
  }
}
