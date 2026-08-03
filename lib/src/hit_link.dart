import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Registry of deferred hit/paint targets for a [HitScope].
///
/// Owned by [HitScope] by default. Pass an explicit instance to share a
/// registry across scopes, or to register a target with a non-nearest scope.
///
/// Listeners are notified when targets are added/removed, when geometry may
/// have changed ([markGeometryDirty]), or when a deferred descendant needs
/// paint ([descendantNeedsPaint]).
class HitLink extends ChangeNotifier {
  /// Creates an empty deferred-target registry.
  HitLink();

  final List<HitDeferRegistration> _targets = <HitDeferRegistration>[];

  /// Snapshot of registered targets for tests / introspection.
  ///
  /// Hit-testing walks targets newest-first via [forEachReversed] /
  /// [anyReversed]; registration order is oldest-first.
  List<HitDeferRegistration> get targets =>
      List<HitDeferRegistration>.unmodifiable(_targets);

  /// Whether [target] is currently registered.
  bool contains(HitDeferRegistration target) => _targets.contains(target);

  /// Notifies listeners that a deferred descendant needs to be painted.
  ///
  /// Used by paint-deferred targets so [RenderHitScope] can repaint without
  /// the target painting locally.
  void descendantNeedsPaint() => notifyListeners();

  /// Notifies listeners that registered targets' bounds or transforms may
  /// have changed.
  void markGeometryDirty() => notifyListeners();

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

  /// Registers [target] if it is not already present and notifies listeners.
  void add(HitDeferRegistration target) {
    if (!_targets.contains(target)) {
      _targets.add(target);
      notifyListeners();
    }
  }

  /// Unregisters [target] if present and notifies listeners.
  void remove(HitDeferRegistration target) {
    if (_targets.remove(target)) {
      notifyListeners();
    }
  }

  /// Clears all registered targets and notifies listeners when any were
  /// removed.
  void removeAll() {
    if (_targets.isNotEmpty) {
      _targets.clear();
      notifyListeners();
    }
  }
}

/// Contract implemented by render objects that participate in deferred hit
/// testing and optional deferred paint.
///
/// Implemented by [RenderHitDefer] and by [RenderHitLayer] when its hit child
/// overflows layout size.
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
  /// scanning further deferred targets.
  HitTestBehavior get hitBehavior;

  /// Whether [HitScope] should paint this target after the scoped subtree.
  bool get deferPaintOnTop;

  /// Whether [HitScope] should paint this target under the scoped subtree.
  bool get deferPaintUnder;

  /// Leader link for composited [deferPaintOnTop] paint. Null when unused.
  ///
  /// [HitScope] paints a [FollowerLayer] so deferred paint tracks scroll /
  /// transforms without requiring the scope to repaint every frame.
  LayerLink? get deferredPaintLink;
}
