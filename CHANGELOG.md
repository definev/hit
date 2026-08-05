## 1.2.4

- Add **Probe** mode to the hit DevTools extension: tap the connected app to
  list every hit area under that point (`Hit.probed`) with diagnostic notes
  for misses. Mutually exclusive with Select; reuses cancelled pointer
  intercept. Service extensions: `ext.hit.getProbeMode` /
  `ext.hit.setProbeMode` (`debugHitProbeEnabled`).
- Fix Select / highlight IDE jump for `HitScope`, `SliverHitScope`, and
  `HitDefer`: inspect the public widget call site instead of the private
  render-object wrapper (`_HitScopeRenderObjectWidget`, etc.).
- Include `globalBounds` / target hit bounds for `SliverHitScope` in DevTools
  snapshots so Probe / Select can detect sliver scopes (previously omitted
  because they are not `RenderBox`).
- Deduplicate Probe hits: a deferred `HitLayer` / `HitDefer` is listed once
  (enriched with scope id/label) instead of both `layer` and `deferredTarget`.
- Probe marks the Flutter hit-test **winner** (deepest hit-package node on
  the real path), sorts path hits leaf→root to mirror nesting / opaque
  deferred order, and labels AABB-only overlaps as `overlap only`.
- `HitScope.hitTest` now adds itself to the hit-test path (like
  `SliverHitScope`) so Probe can show delivering scopes as `in path`.

## 1.2.3

- Harden DevTools / debug paths for profile and release: `kDebugMode` guards
  on service-extension registration and snapshot/probe APIs; assert-strip
  DevTools init and deferred debug paint from creation/paint hot paths; lazy
  debug-paint signal so release builds allocate no debug notifier.
- Remove scroll-forced debug repaint listeners from `HitScope` /
  `SliverHitScope`; deferred overlays track scroll via `LayerLink`
  Leader/Follower only.

## 1.2.2

- Reorganize README for a beginner-first path: install → quick start →
  common mistakes → patterns → API / debugging / migration.

## 1.2.1

- Add `debugPaintHitAreas` — when enabled (or when Flutter's
  `debugPaintSizeEnabled` / DevTools **Debug Paint** is on), `HitLayer` and
  deferred targets paint a dashed overlay of their real hit-test bounds,
  including overflow regions drawn from `HitScope` / `SliverHitScope`.
- Deferred hit-area debug overlays track `paintChild` / scroll via composited
  `LeaderLayer` / `FollowerLayer` (`HitDeferRegistration.hitDebugLeaderLink`),
  matching `HitDeferPaint.onTop` paint tracking.
- Debug paint / DevTools paths are assert-gated: release and profile builds
  never enable overlays or debug compositing.
- Add a **DevTools extension** (`extension/devtools`) with:
  - remote toggle for hit-area overlays and **Select** mode
  - hierarchical **Hit Scope Tree** (`TreeView`) of scopes and targets
  - **Hit Layer Details** + **Hit Analysis** panels
  - tap a debug-painted hit area in the app (Select mode) to jump/highlight
    the matching tree node (`Hit.selected` extension event) and open the
    widget call site in the IDE (Widget Inspector `navigate` ToolEvent)
  - point probe (“why did this miss?”) and yellow target highlight
- Service extensions register automatically in debug when a `HitScope`,
  `HitLayer`, or `HitDefer` is created (`ensureHitDevToolsInitialized`).
- Add optional `debugLabel` on `HitLayer`, `HitDefer`, `HitScope`, and
  `SliverHitScope` (also on `HitDeferRegistration`) for DevTools / Inspector.

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
