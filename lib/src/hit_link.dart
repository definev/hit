import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Registry of deferred hit/paint targets for a [HitScope].
///
/// Owned by [HitScope] by default. Pass an explicit instance to share a
/// registry across scopes, or to register a target with a non-nearest scope.
///
/// Paint and geometry notifications are separate:
///
/// * [paintListenable] / [descendantNeedsPaint] — membership changes and
///   deferred paint invalidation (scopes subscribe to repaint followers).
/// * [geometryListenable] / [markGeometryDirty] — bounds/transform may have
///   changed. Hit testing recomputes transforms each pass, so scopes do
///   **not** repaint on geometry alone (composited [HitDeferPaint.onTop]
///   tracks scroll without a scope repaint).
class HitLink {
  /// Creates an empty deferred-target registry.
  HitLink();

  final List<HitDeferRegistration> _targets = <HitDeferRegistration>[];
  final Set<HitDeferRegistration> _targetSet = HashSet<HitDeferRegistration>(
    equals: identical,
    hashCode: identityHashCode,
  );

  final _HitLinkSignal _paint = _HitLinkSignal();
  final _HitLinkSignal _geometry = _HitLinkSignal();

  /// Notified on [add] / [remove] / [removeAll] and [descendantNeedsPaint].
  Listenable get paintListenable => _paint;

  /// Notified on [markGeometryDirty].
  Listenable get geometryListenable => _geometry;

  /// Snapshot of registered targets for tests / introspection.
  ///
  /// Hit-testing walks targets newest-first via [forEachReversed] /
  /// [anyReversed]; registration order is oldest-first.
  @visibleForTesting
  List<HitDeferRegistration> get targets =>
      List<HitDeferRegistration>.unmodifiable(_targets);

  /// Whether [target] is currently registered (identity, O(1)).
  bool contains(HitDeferRegistration target) => _targetSet.contains(target);

  /// Adds a paint listener (membership / deferred paint).
  void addPaintListener(VoidCallback listener) => _paint.addListener(listener);

  /// Removes a paint listener.
  void removePaintListener(VoidCallback listener) =>
      _paint.removeListener(listener);

  /// Adds a geometry listener (bounds / transforms).
  void addGeometryListener(VoidCallback listener) =>
      _geometry.addListener(listener);

  /// Removes a geometry listener.
  void removeGeometryListener(VoidCallback listener) =>
      _geometry.removeListener(listener);

  /// Notifies [paintListenable] that a deferred descendant needs paint.
  ///
  /// Used by [HitDeferPaint.onTop] targets so the enclosing HitScope can
  /// sync follower layers without the target painting locally.
  void descendantNeedsPaint() => _paint.notify();

  /// Notifies [geometryListenable] that targets' bounds or transforms may
  /// have changed.
  ///
  /// Does **not** notify paint listeners — hit testing reads live transforms,
  /// and composited on-top paint tracks scroll via leader/follower.
  void markGeometryDirty() => _geometry.notify();

  /// Invokes [action] for each target in registration order (oldest first).
  void forEach(void Function(HitDeferRegistration target) action) {
    for (final HitDeferRegistration target in _targets) {
      action(target);
    }
  }

  /// Invokes [action] for each target newest-first (last registered first).
  ///
  /// Matches the order used for deferred hit testing.
  void forEachReversed(void Function(HitDeferRegistration target) action) {
    for (var i = _targets.length - 1; i >= 0; i--) {
      action(_targets[i]);
    }
  }

  /// Walks targets newest-first; stops and returns `true` when [test] is true.
  bool anyReversed(bool Function(HitDeferRegistration target) test) {
    for (var i = _targets.length - 1; i >= 0; i--) {
      if (test(_targets[i])) {
        return true;
      }
    }
    return false;
  }

  /// Registers [target] if it is not already present and notifies paint
  /// listeners.
  void add(HitDeferRegistration target) {
    if (_targetSet.add(target)) {
      _targets.add(target);
      _paint.notify();
    }
  }

  /// Unregisters [target] if present and notifies paint listeners.
  void remove(HitDeferRegistration target) {
    if (_targetSet.remove(target)) {
      _targets.remove(target);
      _paint.notify();
    }
  }

  /// Clears all registered targets and notifies paint listeners when any were
  /// removed.
  void removeAll() {
    if (_targets.isNotEmpty) {
      _targets.clear();
      _targetSet.clear();
      _paint.notify();
    }
  }

  /// Disposes paint and geometry listenables.
  void dispose() {
    _paint.dispose();
    _geometry.dispose();
  }
}

class _HitLinkSignal extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Contract implemented by render objects that participate in deferred hit
/// testing and optional deferred paint.
///
/// Implemented by deferred hit targets ([HitDefer]) and by
/// [HitLayer] when its hit child overflows layout size.
abstract class HitDeferRegistration {
  /// Box used for deferred paint positioning; null if this target does not
  /// paint through the scope.
  RenderBox? get registeredChild;

  /// Box whose transform maps [HitScope] coordinates into hit-test space.
  RenderBox get hitTestBox;

  /// Hit area in [hitTestBox] coordinates.
  ///
  /// May extend outside [RenderBox.size] (for example an overflowing
  /// [HitLayer] hit child).
  Rect get deferredHitBounds;

  /// Hit-tests this target in [hitTestBox] local coordinates.
  ///
  /// [position] may lie outside [RenderBox.size].
  bool hitTestDeferred(BoxHitTestResult result, Offset position);

  /// How this target participates in the [HitScope] deferred hit walk.
  ///
  /// When [HitTestBehavior.opaque] and this target hits, the scope stops
  /// scanning further deferred targets **and** does not hit-test the scoped
  /// subtree. [HitTestBehavior.translucent] still allows the subtree walk.
  HitTestBehavior get hitBehavior;

  /// How [HitScope] paints this target relative to the scoped subtree.
  HitDeferPaint get deferPaint;

  /// Leader link for composited [HitDeferPaint.onTop] paint. Null when unused.
  ///
  /// [HitScope] paints a [FollowerLayer] so deferred paint tracks scroll /
  /// transforms without requiring the scope to repaint every frame.
  LayerLink? get deferredPaintLink;
}

/// How a deferred target is painted by its enclosing [HitScope].
enum HitDeferPaint {
  /// Child paints in place; only hit testing is deferred.
  none,

  /// [HitScope] paints after the scoped subtree via a composited follower.
  onTop,
}
