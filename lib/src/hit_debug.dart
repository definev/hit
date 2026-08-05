import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Whether [HitLayer] / [HitDefer] paint their hit-testable bounds.
///
/// **Debug builds only.** In release / profile (asserts disabled), the setter
/// is a no-op and [hitDebugPaintingEnabled] is always `false`, so overlays and
/// debug compositing never run.
///
/// When `true` in debug mode, overflowing / deferred hit areas are drawn as a
/// translucent fill with a dashed outline so you can see what is tappable —
/// including regions outside layout size.
///
/// Also enabled automatically when Flutter's [debugPaintSizeEnabled] is on
/// ("Debug Paint" in DevTools), since layout outlines alone hide expanded
/// hit targets.
///
/// Changing this value repaints active hit render objects. Prefer toggling
/// from a debug menu or:
///
/// ```dart
/// import 'package:flutter/rendering.dart';
/// import 'package:hit/hit.dart';
///
/// debugPaintHitAreas = true;
/// // or: debugPaintSizeEnabled = true;
/// ```
bool get debugPaintHitAreas => _debugPaintHitAreas;
set debugPaintHitAreas(bool value) {
  assert(() {
    if (_debugPaintHitAreas == value) {
      return true;
    }
    _debugPaintHitAreas = value;
    _hitDebugPaintSignal.notify();
    return true;
  }());
}

bool _debugPaintHitAreas = false;

_HitDebugSignal? _debugPaintHitAreasSignal;

_HitDebugSignal get _hitDebugPaintSignal =>
    _debugPaintHitAreasSignal ??= _HitDebugSignal();

/// When non-null, the hit target with this [identityHashCode] is painted with
/// a stronger highlight (used by the DevTools extension).
///
/// Debug builds only; the setter is a no-op when asserts are disabled.
int? get debugHighlightHitTargetId => _debugHighlightHitTargetId;
set debugHighlightHitTargetId(int? value) {
  assert(() {
    if (_debugHighlightHitTargetId == value) {
      return true;
    }
    _debugHighlightHitTargetId = value;
    _hitDebugPaintSignal.notify();
    return true;
  }());
}

int? _debugHighlightHitTargetId;

/// When `true`, a pointer down on a hit area selects it for DevTools
/// (sets [debugHighlightHitTargetId] and posts `Hit.selected`).
///
/// Debug builds only; the setter is a no-op when asserts are disabled.
/// Intended for inspect mode from the hit DevTools extension — taps are
/// cancelled so the app does not also handle them.
bool get debugHitSelectEnabled => _debugHitSelectEnabled;
set debugHitSelectEnabled(bool value) {
  assert(() {
    if (_debugHitSelectEnabled == value) {
      return true;
    }
    _debugHitSelectEnabled = value;
    _hitDebugPaintSignal.notify();
    return true;
  }());
}

bool _debugHitSelectEnabled = false;

/// When `true`, a pointer down probes hit areas for DevTools
/// (posts `Hit.probed` with the full probe payload).
///
/// Debug builds only; the setter is a no-op when asserts are disabled.
/// Mutually exclusive with [debugHitSelectEnabled] when toggled via
/// DevTools service extensions. Taps are cancelled so the app does not
/// also handle them.
bool get debugHitProbeEnabled => _debugHitProbeEnabled;
set debugHitProbeEnabled(bool value) {
  assert(() {
    if (_debugHitProbeEnabled == value) {
      return true;
    }
    _debugHitProbeEnabled = value;
    _hitDebugPaintSignal.notify();
    return true;
  }());
}

bool _debugHitProbeEnabled = false;

/// Whether [target] should use the DevTools highlight style.
bool isHitDebugHighlighted(Object target) =>
    _debugHighlightHitTargetId != null &&
    identityHashCode(target) == _debugHighlightHitTargetId;

/// Fill used when [isHitDebugHighlighted] is true (yellow, matches DevTools).
const Color hitDebugHighlightFillColor = Color(0x66FFD60A);
const Color hitDebugHighlightStrokeColor = Color(0xFFFFD60A);

/// Whether hit-area debug overlays should paint right now.
///
/// Always `false` in release / profile (asserts disabled). In debug builds,
/// true when [debugPaintHitAreas] is set or [debugPaintSizeEnabled] is on.
bool get hitDebugPaintingEnabled {
  var enabled = false;
  assert(() {
    enabled = _debugPaintHitAreas || debugPaintSizeEnabled;
    return true;
  }());
  return enabled;
}

/// Registers [listener] for [debugPaintHitAreas] changes.
void addHitDebugPaintListener(VoidCallback listener) {
  assert(() {
    _hitDebugPaintSignal.addListener(listener);
    return true;
  }());
}

/// Removes a [addHitDebugPaintListener] registration.
void removeHitDebugPaintListener(VoidCallback listener) {
  assert(() {
    _debugPaintHitAreasSignal?.removeListener(listener);
    return true;
  }());
}

/// Fill / stroke used by [paintHitAreaDebugOverlay].
const Color hitDebugFillColor = Color(0x40FF2D55);
const Color hitDebugStrokeColor = Color(0xFFFF2D55);

/// Paints a translucent hit-area overlay onto [canvas].
///
/// **Debug builds only** — no-op when asserts are disabled (release / profile).
///
/// Used by hit render objects and available for manual overlays (for example
/// when comparing against plain Flutter widgets that are not [HitLayer]).
void paintHitAreaDebugOverlay(
  Canvas canvas,
  Rect rect, {
  Color? fill,
  Color? stroke,
  double strokeWidth = 1.0,
  double dash = 4.0,
  double gap = 3.0,
  double radius = 4.0,
  bool highlighted = false,
}) {
  assert(() {
    if (rect.isEmpty) {
      return true;
    }
    final Color resolvedFill =
        fill ?? (highlighted ? hitDebugHighlightFillColor : hitDebugFillColor);
    final Color resolvedStroke = stroke ??
        (highlighted ? hitDebugHighlightStrokeColor : hitDebugStrokeColor);
    final RRect shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(shape, Paint()..color = resolvedFill);

    final Paint paint = Paint()
      ..color = resolvedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? strokeWidth + 0.5 : strokeWidth;
    final Path path = Path()..addRRect(shape.deflate(strokeWidth * 0.5));
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final double next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
    return true;
  }());
}

class _HitDebugSignal extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Shared debug-overlay attachment for hit render objects.
mixin HitDebugPaintMixin on RenderObject {
  bool _listeningHitDebug = false;

  /// Call from [RenderObject.attach]. No-op when asserts are disabled.
  void attachHitDebugPaintListener() {
    assert(() {
      if (!_listeningHitDebug) {
        addHitDebugPaintListener(_onHitDebugPaintFlagChanged);
        _listeningHitDebug = true;
      }
      return true;
    }());
  }

  /// Call from [RenderObject.detach]. No-op when asserts are disabled.
  void detachHitDebugPaintListener() {
    assert(() {
      if (_listeningHitDebug) {
        removeHitDebugPaintListener(_onHitDebugPaintFlagChanged);
        _listeningHitDebug = false;
      }
      return true;
    }());
  }

  void _onHitDebugPaintFlagChanged() {
    // Deferred overlays use a LeaderLayer only while debug painting is on.
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  /// Paints [rect] (already in the paint coordinate space) when debugging.
  ///
  /// No-op when asserts are disabled.
  void paintHitDebugOverlayIfEnabled(
    PaintingContext context,
    Rect rect, {
    Object? target,
  }) {
    assert(() {
      if (hitDebugPaintingEnabled) {
        paintHitAreaDebugOverlay(
          context.canvas,
          rect,
          highlighted: target != null && isHitDebugHighlighted(target),
        );
      }
      return true;
    }());
  }
}
