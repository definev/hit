## 1.2.0

**Breaking** deferred-hit API cleanup:

- Replace static `Hit.defer` / `Hit.before` with widget `HitDefer`.
- Replace `paintOnTop` / `paintUnder` booleans with `HitDeferPaint`
  (`none`, `onTop`).
- Remove under-scope deferred paint (`Hit.before` / `paintUnder`); use
  `HitDeferPaint.onTop` (composited) instead.
- Replace `HitDeferRegistration.deferPaintOnTop` /
  `deferPaintUnder` with `deferPaint`.
- `HitLink` no longer extends `ChangeNotifier`. Use `paintListenable` /
  `addPaintListener` for membership and deferred paint; use
  `geometryListenable` / `addGeometryListener` for
  `markGeometryDirty`. Scopes subscribe to paint only, so geometry dirty
  (e.g. scroll / bounds) does not force a scope repaint.
- `HitLink` membership is identity-based (`identical`) for O(1)
  `contains` / `add`.

### Migration

| Before | After |
| --- | --- |
| `Hit.defer(child: w)` | `HitDefer(child: w)` |
| `Hit.defer(paintOnTop: true, child: w)` | `HitDefer(paint: HitDeferPaint.onTop, child: w)` |
| `Hit.before(child: w)` | `HitDefer(paint: HitDeferPaint.onTop, child: w)` |
| `target.deferPaintOnTop` | `target.deferPaint == HitDeferPaint.onTop` |
| `target.deferPaintUnder` | `target.deferPaint == HitDeferPaint.onTop` |
| `link.addListener(fn)` | `link.addPaintListener(fn)` |
| `link.removeListener(fn)` | `link.removePaintListener(fn)` |

`HitDeferPaint.none` (default) paints in place; only hit testing is deferred.
`onTop` paints after the scoped subtree via a composited leader/follower so
paint tracks scroll without a full `HitScope` repaint.

## 1.1.0

- Add `SliverHitScope` / `SliverHitScopeState` for deferred hits inside
  `CustomScrollView` (and other viewport) sliver trees.
- Introduce `HitScopeHandle`; `HitScope.of` / `maybeOf` now return
  `HitScopeHandle` and resolve the nearest `HitScope` **or** `SliverHitScope`
  (`HitScopeState` / `SliverHitScopeState` both implement the handle).
- Example: Basics + Slivers tabs; settings via `CupertinoMenuAnchor` on the
  navigation bar.

## 1.0.0

Stable release. Public API is the surface exported by `package:hit/hit.dart`:

- `HitLayer`, `HitScope` / `HitScopeState`
- `Hit.defer` / `Hit.before`
- `HitLink`, `HitDeferRegistration`

No breaking changes from 0.3.2. Docs and example now cover common `HitScope`
mistakes (scope too small, clip above scope, missing scope) and scrubbers that
do not fight the page scroll view on small screens.

## 0.3.2

- Fix deferred targets staying on a stale registry when `HitScope.link` changes
  at runtime (inherited notify + re-registration).
- Make overflowing `HitLayer` without a `HitScope`/`link` reject hits outside
  the layout box in release (same contract as the debug assert).
- Remove unused per-pass AABB cache; skip no-op `RenderHitScope.link` updates.
- Add `HitLayer.computeDryLayout`; lazy-create the scope's internal `HitLink`.
- Harden `Hit.defer` null-child hit paths; expand link-swap and overflow tests.

## 0.3.1

- Add package banner and `screenshots` for pub.dev display.
- Point README banner at an absolute GitHub raw URL so it renders on pub.dev.

## 0.3.0

- Narrow the supported public API: `package:hit/hit.dart` exports widgets and
  the registry protocol (`Hit`, `HitLayer`, `HitScope`, `HitScopeState`,
  `HitLink`, `HitDeferRegistration`). Render objects are no longer exported.
- `HitScope.of` now throws a `FlutterError` when no scope is found (was
  assert-only).
- Document deferred `opaque` semantics: stops further deferred scanning **and**
  skips the scoped subtree; document intentional default `behavior` differences
  (`HitLayer` opaque vs `Hit.defer`/`Hit.before` translucent).
- Expand tests: `Hit.before`, nested scopes, explicit outer `HitLink`, opaque
  subtree skip, `HitScope.of` / `maybeOf`, `ClipRect` cull, `Transform`.
- Add GitHub Actions CI (`flutter analyze` + `flutter test`).
- Declare supported platforms in `pubspec.yaml`.

## 0.2.0

- Fix `Hit.defer(paintOnTop: true)` with scroll views: deferred paint uses a
  composited leader/follower so it tracks transforms without a full `HitScope`
  repaint.
- Fix disposed-layer crash when reusing `paintOnTop` follower layers across
  frames (`LayerHandle`).
- Expand example app with more demos (`Hit.before`, resize, window edge, chip,
  list, slider) and Cupertino UI.

## 0.1.0

- Initial release: `HitLayer`, `HitScope`, `Hit.defer` / `Hit.before`, and
  `HitLink`.
