import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hit_link.dart';
import 'hit_scope.dart';

class _HitLayerParentData extends ContainerBoxParentData<RenderBox> {}

/// Separates **layout/paint size** from **hit size**.
///
/// Paints [paintChild] on top of [hitChild] and hit-tests both when
/// [behavior] is [HitTestBehavior.translucent].
///
/// - [paintChild] defines **layout size**.
/// - [hitChild] defines the **hit area** (may be larger) and is placed around
///   [paintChild] via [alignment].
///
/// When [hitChild] overflows the layout box, a [HitScope] ancestor is required
/// so Flutter will still deliver those hits. Non-overflowing layers stay on
/// the normal local hit path and do not register on a [HitLink].
///
/// ```dart
/// HitScope(
///   child: HitLayer(
///     alignment: Alignment.center,
///     hitChild: GestureDetector(
///       behavior: HitTestBehavior.opaque,
///       onTap: onPressed,
///       child: const SizedBox(width: 48, height: 48),
///     ),
///     paintChild: const Icon(Icons.add, size: 24),
///   ),
/// )
/// ```
class HitLayer extends MultiChildRenderObjectWidget {
  /// Creates a layer whose layout follows [paintChild] and whose hit area
  /// follows [hitChild].
  HitLayer({
    super.key,
    this.hitChild,
    this.alignment = Alignment.center,
    this.behavior = HitTestBehavior.translucent,
    this.link,
    required this.paintChild,
  }) : super(
          children: <Widget>[
            if (hitChild != null) hitChild,
            paintChild,
          ],
        );

  /// Gesture / hover layer. Sized independently; may overflow layout.
  final Widget? hitChild;

  /// Visual layer; also defines this widget's layout size.
  final Widget paintChild;

  /// Where [paintChild] sits inside the [hitChild] box (hit is placed around it).
  final AlignmentGeometry alignment;

  /// How [paintChild] and [hitChild] interact during hit testing.
  ///
  /// - [HitTestBehavior.translucent] — test both when they overlap.
  /// - [HitTestBehavior.deferToChild] / [HitTestBehavior.opaque] — prefer
  ///   paint; test hit only if paint missed.
  final HitTestBehavior behavior;

  /// Optional link; defaults to the nearest [HitScope] when hit overflows.
  final HitLink? link;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHitLayer(
      alignment: alignment,
      behavior: behavior,
      hasHitChild: hitChild != null,
      textDirection: Directionality.maybeOf(context),
      link: _resolveLink(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitLayer renderObject) {
    renderObject
      ..alignment = alignment
      ..behavior = behavior
      ..hasHitChild = hitChild != null
      ..textDirection = Directionality.maybeOf(context)
      ..link = _resolveLink(context);
  }

  HitLink? _resolveLink(BuildContext context) {
    if (hitChild == null) {
      return null;
    }
    return link ?? HitScope.maybeOf(context)?.link;
  }
}

/// Render object for [HitLayer].
///
/// Layout size always follows the paint child. The hit child is laid out with
/// loosened constraints and positioned so [alignment] places the paint child
/// inside the hit box.
///
/// When the hit child overflows layout and a [link] is set, this object
/// registers as a [HitDeferRegistration] and local [hitTest] returns `false`
/// so overflow hits are delivered only through [HitScope].
class RenderHitLayer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HitLayerParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HitLayerParentData>
    implements HitDeferRegistration {
  /// Creates a hit/paint layer render object.
  RenderHitLayer({
    required AlignmentGeometry alignment,
    required HitTestBehavior behavior,
    required bool hasHitChild,
    TextDirection? textDirection,
    HitLink? link,
  })  : _alignment = alignment,
        _behavior = behavior,
        _hasHitChild = hasHitChild,
        _textDirection = textDirection {
    this.link = link;
  }

  HitLink? _link;

  /// Registry used when the hit child overflows layout; null when unused.
  HitLink? get link => _link;
  set link(HitLink? value) {
    if (identical(_link, value)) {
      return;
    }
    if (attached) {
      _unlink();
    }
    _link = value;
    if (attached) {
      _syncLinkRegistration();
    }
  }

  AlignmentGeometry _alignment;

  /// Where the paint child sits inside the hit child box.
  AlignmentGeometry get alignment => _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsLayout();
  }

  HitTestBehavior _behavior;

  /// How paint and hit children interact during hit testing.
  @override
  HitTestBehavior get hitBehavior => _behavior;
  set behavior(HitTestBehavior value) {
    if (_behavior == value) {
      return;
    }
    _behavior = value;
  }

  bool _hasHitChild;

  /// Whether a hit child is present in the child list.
  bool get hasHitChild => _hasHitChild;
  set hasHitChild(bool value) {
    if (_hasHitChild == value) {
      return;
    }
    _hasHitChild = value;
    markNeedsLayout();
  }

  TextDirection? _textDirection;

  /// Used to resolve [alignment] when it is directional.
  TextDirection? get textDirection => _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  RenderBox? get registeredChild => null;

  @override
  RenderBox get hitTestBox => this;

  @override
  Rect get deferredHitBounds {
    final RenderBox? hit = hitRenderChild;
    if (hit == null) {
      return Offset.zero & size;
    }
    final Offset offset = (hit.parentData! as _HitLayerParentData).offset;
    return offset & hit.size;
  }

  @override
  bool get deferPaintOnTop => false;

  @override
  bool get deferPaintUnder => false;

  @override
  LayerLink? get deferredPaintLink => null;

  /// The hit-area child, or null when [hasHitChild] is false.
  RenderBox? get hitRenderChild =>
      _hasHitChild && firstChild != null ? firstChild : null;

  /// The paint/layout child.
  RenderBox? get paintRenderChild {
    if (!_hasHitChild) {
      return firstChild;
    }
    final RenderBox? hit = firstChild;
    if (hit == null) {
      return null;
    }
    return (hit.parentData! as _HitLayerParentData).nextSibling;
  }

  bool get _hitOverflowsLayout {
    final RenderBox? hit = hitRenderChild;
    if (hit == null) {
      return false;
    }
    final Offset offset = (hit.parentData! as _HitLayerParentData).offset;
    final Rect hitRect = offset & hit.size;
    final Rect layoutRect = Offset.zero & size;
    return hitRect.left < layoutRect.left ||
        hitRect.top < layoutRect.top ||
        hitRect.right > layoutRect.right ||
        hitRect.bottom > layoutRect.bottom;
  }

  bool get _defersHit => _link != null && _hitOverflowsLayout;

  Rect? _lastRegisteredBounds;

  /// Registers only when [hitChild] overflows layout size.
  void _syncLinkRegistration() {
    final HitLink? link = _link;
    if (link == null) {
      _lastRegisteredBounds = null;
      return;
    }
    final bool shouldLink = _hasHitChild && hasSize && _hitOverflowsLayout;
    if (shouldLink) {
      final Rect bounds = deferredHitBounds;
      if (link.contains(this)) {
        if (_lastRegisteredBounds != bounds) {
          _lastRegisteredBounds = bounds;
          link.markGeometryDirty();
        }
      } else {
        _lastRegisteredBounds = bounds;
        link.add(this);
      }
    } else {
      _lastRegisteredBounds = null;
      link.remove(this);
    }
  }

  void _unlink() {
    _link?.remove(this);
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    // Registration waits until performLayout knows overflow.
  }

  @override
  void detach() {
    _unlink();
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HitLayerParentData) {
      child.parentData = _HitLayerParentData();
    }
  }

  Alignment get _resolvedAlignment {
    return _alignment.resolve(_textDirection);
  }

  @override
  void performLayout() {
    final RenderBox? hit = hitRenderChild;
    final RenderBox? paint = paintRenderChild;

    if (paint == null) {
      size = constraints.smallest;
      if (attached) {
        _syncLinkRegistration();
      }
      return;
    }

    // Layout size always follows paintChild.
    paint.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(paint.size);

    final _HitLayerParentData paintData =
        paint.parentData! as _HitLayerParentData;
    paintData.offset = Offset.zero;

    if (hit != null) {
      // hitChild sizes itself; may be larger than paint / layout.
      hit.layout(constraints.loosen(), parentUsesSize: true);
      final _HitLayerParentData hitData =
          hit.parentData! as _HitLayerParentData;
      // Place hit so paint sits at [alignment] inside the hit box.
      hitData.offset = _resolvedAlignment.alongOffset(
        Offset(size.width - hit.size.width, size.height - hit.size.height),
      );
    }

    // Re-evaluate deferred registration after layout (overflow may change).
    if (attached) {
      _syncLinkRegistration();
      assert(() {
        if (_hitOverflowsLayout && _link == null) {
          throw FlutterError(
            'HitLayer: hitChild overflows paintChild layout size, but no '
            'HitScope ancestor (or explicit link) was found.\n'
            'Wrap a large enough ancestor in HitScope so overflow hits can be '
            'delivered outside the layout box.',
          );
        }
        return true;
      }());
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? hit = hitRenderChild;
    if (hit != null) {
      final _HitLayerParentData hitData =
          hit.parentData! as _HitLayerParentData;
      context.paintChild(hit, offset + hitData.offset);
    }
    final RenderBox? paint = paintRenderChild;
    if (paint != null) {
      final _HitLayerParentData paintData =
          paint.parentData! as _HitLayerParentData;
      context.paintChild(paint, offset + paintData.offset);
    }
  }

  bool _hitTestHitChild(BoxHitTestResult result, Offset position) {
    final RenderBox? hit = hitRenderChild;
    if (hit == null) {
      return false;
    }
    final _HitLayerParentData parentData =
        hit.parentData! as _HitLayerParentData;
    final Rect hitRect = parentData.offset & hit.size;
    if (!hitRect.contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return hit.hitTest(result, position: transformed);
      },
    );
  }

  bool _hitTestPaintChild(BoxHitTestResult result, Offset position) {
    final RenderBox? paint = paintRenderChild;
    if (paint == null) {
      return false;
    }
    final _HitLayerParentData parentData =
        paint.parentData! as _HitLayerParentData;
    final Rect paintRect = parentData.offset & paint.size;
    if (!paintRect.contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return paint.hitTest(result, position: transformed);
      },
    );
  }

  bool _hitTestInternal(BoxHitTestResult result, Offset position) {
    final RenderBox? hit = hitRenderChild;
    final bool inLayout = (Offset.zero & size).contains(position);
    final bool inHit = hit != null &&
        ((hit.parentData! as _HitLayerParentData).offset & hit.size).contains(
          position,
        );

    if (!inLayout && !inHit) {
      return false;
    }

    var paintHit = false;
    var hitChildHit = false;

    if (inLayout) {
      paintHit = _hitTestPaintChild(result, position);
    }

    switch (_behavior) {
      case HitTestBehavior.translucent:
        hitChildHit = _hitTestHitChild(result, position);
      case HitTestBehavior.deferToChild:
        if (!paintHit) {
          hitChildHit = _hitTestHitChild(result, position);
        }
      case HitTestBehavior.opaque:
        if (!paintHit) {
          hitChildHit = _hitTestHitChild(result, position);
        }
    }

    final didHit = paintHit || hitChildHit;
    if (didHit) {
      result.add(BoxHitTestEntry(this, position));
    }
    return didHit;
  }

  @override
  bool hitTestDeferred(BoxHitTestResult result, Offset position) {
    return _hitTestInternal(result, position);
  }

  /// Local hit test; returns `false` when overflow hits are deferred to
  /// [HitScope].
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Overflow hits are delivered only via HitScope.
    if (_defersHit) {
      return false;
    }
    return _hitTestInternal(result, position);
  }
}
