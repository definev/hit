import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Registry of deferred hit/paint targets for a [HitScope].
class HitLink extends ChangeNotifier {
  HitLink();

  final List<HitDeferRegistration> _targets = <HitDeferRegistration>[];

  /// Snapshot for tests / introspection. Hit-test uses [forEachReversed].
  List<HitDeferRegistration> get targets =>
      List<HitDeferRegistration>.unmodifiable(_targets);

  bool contains(HitDeferRegistration target) => _targets.contains(target);

  void descendantNeedsPaint() => notifyListeners();

  /// Bounds or transforms of registered targets may have changed.
  void markGeometryDirty() => notifyListeners();

  void forEach(void Function(HitDeferRegistration target) action) {
    for (final HitDeferRegistration target in _targets) {
      action(target);
    }
  }

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

  void add(HitDeferRegistration target) {
    if (!_targets.contains(target)) {
      _targets.add(target);
      notifyListeners();
    }
  }

  void remove(HitDeferRegistration target) {
    if (_targets.remove(target)) {
      notifyListeners();
    }
  }

  void removeAll() {
    if (_targets.isNotEmpty) {
      _targets.clear();
      notifyListeners();
    }
  }
}

/// Implemented by [RenderHitDefer] and [RenderHitLayer] (when hitChild overflows).
abstract class HitDeferRegistration {
  /// Box used for deferred paint positioning; null if this target does not paint.
  RenderBox? get registeredChild;

  /// Box whose transform maps [HitScope] coordinates into hit-test space.
  RenderBox get hitTestBox;

  /// Hit area in [hitTestBox] coordinates (may extend outside [RenderBox.size]).
  Rect get deferredHitBounds;

  /// Hit-test in [hitTestBox] local coordinates (may be outside [RenderBox.size]).
  bool hitTestDeferred(BoxHitTestResult result, Offset position);

  HitTestBehavior get hitBehavior;

  bool get deferPaintOnTop;

  bool get deferPaintUnder;

  /// Leader link for composited [deferPaintOnTop] paint. Null when unused.
  ///
  /// [HitScope] paints a [FollowerLayer] so deferred paint tracks scroll /
  /// transforms without requiring the scope to repaint every frame.
  LayerLink? get deferredPaintLink;
}
