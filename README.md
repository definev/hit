<p align="center">
  <img src="https://raw.githubusercontent.com/definev/hit/main/assets/banner.png" alt="hit — expand touch targets without growing layout" />
</p>

Separate **paint/layout size** from **hit size** in Flutter, and deliver taps that fall outside a widget’s layout box.

Use it when a control must stay visually small (icon, grip, 1px edge, chip ×) but still meet a comfortable / WCAG touch target without pushing neighbors.

**Live demo:** [hit-one-snowy.vercel.app](https://hit-one-snowy.vercel.app/)

## Table of contents

1. [Why](#why)
2. [Install](#install)
3. [Quick start](#quick-start)
4. [The two pieces you need](#the-two-pieces-you-need)
5. [Common mistakes](#common-mistakes--troubleshooting)
6. [More patterns](#more-patterns)
7. [API reference](#api-reference)
8. [Debugging](#debugging)
9. [Performance](#performance-notes)
10. [Migrating from 1.1.x](#migrating-from-11x)
11. [Example app](#example-app)

## Why

Flutter layout and hit-testing share the same box. Growing padding to enlarge a tap target also grows layout. Overflowing a child past its parent usually **stops receiving hits**.

`hit` splits those concerns: the visual stays small; the tap target can be larger (or hang outside a parent) without breaking neighbors.

Deferred out-of-bounds hit testing is inspired by [`defer_pointer`](https://pub.dev/packages/defer_pointer) ([gskinnerTeam/flutter-defer-pointer](https://github.com/gskinnerTeam/flutter-defer-pointer)): a handler higher in the tree (`HitScope`) receives hits for targets that opt out of local hit-testing (`HitDefer` / overflowing `HitLayer`).

## Install

```yaml
dependencies:
  hit: ^1.2.3
```

```dart
import 'package:flutter/material.dart';
import 'package:hit/hit.dart';
```

## Quick start

Minimum icon with a 48×48 hit target — layout stays 24×24.

`HitScope` must sit on an ancestor whose **layout box covers the expanded hit area**. Pad the scope (or place it on a larger panel / page) so the overflow stays inside.

```dart
HitScope(
  // 12px pad absorbs the overflow of a centered 24→48 expansion.
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        HitLayer(
          alignment: Alignment.center,
          behavior: HitTestBehavior.deferToChild,
          hitChild: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: const SizedBox(width: 48, height: 48),
          ),
          paintChild: const IgnorePointer(
            child: Icon(Icons.add, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        const Text('New item'),
      ],
    ),
  ),
)
```

Whenever `hitChild` overflows `paintChild`, wrap a covering ancestor in `HitScope`. Prefer several small scopes (per padded row / panel) over one app-wide scope.

## The two pieces you need

| Piece | Role |
| --- | --- |
| `HitLayer` | Layout follows `paintChild`; `hitChild` can be larger and overflow |
| `HitScope` | Delivers overflow / out-of-bounds hits to registered targets |

Later you may also use `HitDefer` (hanging widgets without `HitLayer`) and `SliverHitScope` (same idea inside scroll slivers). See [More patterns](#more-patterns).

## Common mistakes & troubleshooting

Most “taps don’t work on the overflow” bugs are the same root cause: **Flutter only hit-tests a child inside that child’s layout box.** `HitScope` can deliver deferred hits, but only if a pointer event actually reaches the scope.

### Mistake 1 — scope too small

Wrapping `HitScope` only around the tiny control leaves the expanded hit area outside the scope’s layout box. Parents never walk there, so the overflow never gets a chance.

```text
  ✗ Wrong — HitScope == paint size (24×24)

       hit area (48×48) — outside scope, never tested
      ┌ · · · · · · · · ┐
      ·  ┌───────────┐  ·
      ·  │ HitScope  │  ·
      ·  │ ┌───────┐ │  ·
      ·  │ │ paint │ │  ·
      ·  │ │ 24×24 │ │  ·
      ·  │ └───────┘ │  ·
      ·  └───────────┘  ·
      └ · · · · · · · · ┘


  ✓ Right — HitScope covers the expanded hit (pad / larger ancestor)

      ┌─────────────────────┐
      │ HitScope + padding  │
      │   ┌─────────────┐   │
      │   │  hit 48×48  │   │
      │   │  ┌───────┐  │   │
      │   │  │ paint │  │   │
      │   │  │ 24×24 │  │   │
      │   │  └───────┘  │   │
      │   └─────────────┘   │
      └─────────────────────┘
```

**Fix:** add padding under the scope, or move `HitScope` up to a panel / row / page that already covers the overflow.

### Mistake 2 — clip or tight parent above the scope

```text
  ✗ ClipRect / tight box above HitScope

      ┌──────── ClipRect ────────┐
      │  ┌──── HitScope ────┐    │  ← clip’s layout box
      │  │   hit overflows… │····│····  ← events never enter here
      │  └──────────────────┘    │
      └──────────────────────────┘
```

**Fix:** put `HitScope` **above** the clip, or remove / relax the clip for that region. Same idea for tight `SizedBox` / `OverflowBox` parents that shrink the walk.

### Mistake 3 — missing `HitScope`

Overflowing `HitLayer` and `HitDefer` need a scope (or an explicit `HitLink` wired to one). Without it, only the layout box is hittable; debug builds assert.

```text
  pointer → parent walk → HitLayer layout box only
                          └── overflow corners: ignored
```

**Fix:** wrap a covering ancestor in `HitScope`.

### Checklist

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Corners of a 48×48 hit miss | Scope / parent same size as paint | Pad under scope, or lift scope |
| Works in center, fails on overflow | Scope too tight or clip above | Cover overflow; move scope above clip |
| Assert / no hits outside box | No `HitScope` | Add one that covers the hit area |
| Wrong nested target wins | Nearest scope / walk order | Use explicit `link`, or restructure scopes |

## More patterns

### Hanging badge with `HitDefer`

For widgets that hang outside a parent without using `HitLayer`. Keep the hanging child inside the scope’s layout box (padding is the usual fix):

```dart
HitScope(
  child: Padding(
    // Absorbs the badge hanging 12px outside the card.
    padding: const EdgeInsets.all(12),
    child: SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          Positioned(
            right: -12,
            top: -12,
            child: HitDefer(
              paint: HitDeferPaint.onTop, // or none (default)
              behavior: HitTestBehavior.opaque,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBadgeTap,
                child: const CircleAvatar(radius: 18),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### Slivers with `SliverHitScope`

Same deferred contract as `HitScope`, for sliver subtrees inside a `CustomScrollView` (or other viewport):

```dart
CustomScrollView(
  slivers: [
    SliverHitScope(
      // link: myLink,
      sliver: SliverList.list(
        children: [
          // HitLayer / HitDefer descendants
        ],
      ),
    ),
  ],
)
```

Put it in the `slivers` list (or nest it under another sliver parent). Do **not** pass a box child directly — wrap boxes with `SliverToBoxAdapter` / list / grid slivers as usual.

Coverage rule: the pointer must land inside this sliver’s hit-test extent (and cross-axis extent). Overflow that leaves the sliver (or the viewport) still needs a larger enclosing scope.

## API reference

Stable surface from `package:hit/hit.dart`:

- `HitLayer`, `HitScope` / `HitScopeState`, `SliverHitScope` / `SliverHitScopeState`, `HitScopeHandle`
- `HitDefer`, `HitDeferPaint`
- `HitLink`, `HitDeferRegistration`
- `debugPaintHitAreas`, `paintHitAreaDebugOverlay`, `ensureHitDevToolsInitialized`
- Optional `debugLabel` on `HitLayer` / `HitDefer` / `HitScope` / `SliverHitScope`

### `HitLayer`

- **`paintChild`** — visual layer; defines layout size
- **`hitChild`** — gesture / hover layer; may be larger
- **`alignment`** — where paint sits inside the hit box (`Alignment.center` by default)
- **`behavior`** — how paint and hit interact (`HitTestBehavior`; default `opaque`)
- **`link`** — optional `HitLink`; defaults to the nearest `HitScope`

When `hitChild` overflows layout, hits are delivered through `HitScope`. Non-overflowing layers stay on the normal local hit path.

Wrap `paintChild` in `IgnorePointer` when you want only `hitChild` to receive gestures (typical with `deferToChild`).

### `HitScope`

Ancestor that hit-tests (and optionally paints) deferred targets.

```dart
HitScope(
  // link: myLink, // optional shared HitLink
  child: /* … */,
)
```

- Nesting is supported; **nearest** scope wins (`HitScope.maybeOf` / `of`), including across `HitScope` and `SliverHitScope`.
- Prefer many small scopes over one app-wide scope — but each scope’s **layout box must cover** the deferred hit areas it serves.
- Pass an explicit `link` to register with an outer scope instead of the nearest one.
- `HitScope.of` throws a `FlutterError` when no scope is found; use `maybeOf` when absence is allowed.

Deferred hit walk order is **newest-first**.

### `SliverHitScope`

See [Slivers with `SliverHitScope`](#slivers-with-sliverhitscope) above for usage.

- `HitScope.of` / `maybeOf` find `SliverHitScope` the same way they find `HitScope`.

### `HitDefer`

See [Hanging badge with `HitDefer`](#hanging-badge-with-hitdefer) above for a full example.

- **`paint`** — `HitDeferPaint.none` (default: paint in place) or `onTop` (after the scoped subtree via composited follower; tracks scroll)
- **`behavior`** — defaults to `translucent`; use `opaque` when a hit should stop further deferred scanning **and** skip the scoped subtree
- **`link`** — optional; defaults to the nearest `HitScope`

### `HitDeferPaint`

| Value | Paint |
| --- | --- |
| `none` | In place (hit only deferred) |
| `onTop` | After scoped subtree (composited; tracks scroll) |

### `HitTestBehavior`

Defaults differ by API and are intentional:

| API | Default |
| --- | --- |
| `HitLayer` | `opaque` |
| `HitDefer` | `translucent` |

| Value | Meaning |
| --- | --- |
| `translucent` | On `HitLayer`: test paint and hit when both overlap. On deferred targets: hit and still walk the scoped subtree |
| `deferToChild` | Prefer paint; hit only if paint missed (`HitLayer`) |
| `opaque` | On `HitLayer`: same as defer for paint vs hit. On deferred targets: stop further deferred scanning **and** skip the scoped subtree |

### `HitLink`

Registry of deferred targets for a scope. Usually owned by `HitScope`; pass explicitly to share or target a non-nearest scope. `HitDeferRegistration` is the extension contract implemented by deferred targets.

Membership uses identity (`identical`) for O(1) `contains` / `add`. Paint and geometry notifications are split:

- **`paintListenable`** — `add` / `remove` / `descendantNeedsPaint` (scopes repaint followers)
- **`geometryListenable`** — `markGeometryDirty` only (does **not** force a scope repaint; hit testing reads live transforms, and `onTop` paint tracks scroll via compositing)

## Debugging

### Hit-area overlays

```dart
import 'package:hit/hit.dart';

debugPaintHitAreas = true; // or enable Flutter DevTools → Debug Paint
```

Overflowing / deferred hit bounds are drawn as a dashed overlay (including
regions outside layout size, painted from the enclosing scope so clips do not
hide them).

### DevTools extension

Apps that depend on `package:hit` get a **hit** tab in Dart DevTools (enable
it from the Extensions menu the first time). The tab can:

- toggle hit-area overlays and **Select** mode remotely
- browse a hierarchical **Hit Scope Tree** (`TreeView`) of scopes and targets
- inspect **Hit Layer Details** and **Hit Analysis** for the selection
- tap a debug-painted hit area in the app (with Select on) to jump/highlight
  the matching tree node and open the `HitLayer` / `HitDefer` / `HitScope`
  call site in the IDE (via Flutter Widget Inspector navigate)
- probe a global `(x, y)` and explain what would hit / why a tap might miss

Service extensions (`ext.hit.*`) register automatically in debug/profile when
any hit widget mounts. Prefer setting `debugLabel` on targets/scopes so the
tree is readable:

```dart
HitLayer(
  debugLabel: 'compose-send',
  // ...
)
```

Rebuild the embedded web assets after changing the
extension UI:

```bash
./tool/build_devtools.sh
```

See [DevTools extensions](https://docs.flutter.dev/tools/devtools/extensions)
and [`devtools_extensions`](https://pub.dev/packages/devtools_extensions).

## Performance notes

Deferred hit-testing is **O(n)** over registered targets on that scope. To keep it fast:

1. Keep `HitScope` tight around overflow regions — but still large enough to cover them
2. Prefer non-overflowing `HitLayer` when the hit fits in paint size (no registration)
3. Prefer `deferToChild` / `opaque` over `translucent` when you do not need dual hits
4. Keep `hitChild` shallow (`GestureDetector` + `SizedBox`)
5. Avoid nesting deferred targets under one huge root scope
6. Use `HitDefer` only when you need out-of-bounds delivery

A handful of min-target / edge / handle layers is cheap. Hundreds of deferred targets under one scope is not.

## Migrating from 1.1.x

`1.2.0` is a **breaking** release for deferred hits:

| Before (`≤1.1`) | After (`1.2`) |
| --- | --- |
| `Hit.defer(child: w)` | `HitDefer(child: w)` |
| `Hit.defer(paintOnTop: true, child: w)` | `HitDefer(paint: HitDeferPaint.onTop, child: w)` |
| `Hit.before(child: w)` | `HitDefer(paint: HitDeferPaint.onTop, child: w)` |
| `target.deferPaintOnTop` / `deferPaintUnder` | `target.deferPaint` (`HitDeferPaint`) |
| `link.addListener` / `removeListener` | `addPaintListener` / `removePaintListener` |

`HitDeferPaint`: `none` (default, paint in place) or `onTop` (after scoped
subtree, composited scroll tracking). Under-scope deferred paint
(`Hit.before` / `paintUnder`) is removed — use `onTop` instead.

`HitLink` splits paint vs geometry notifications: `markGeometryDirty` no
longer forces a scope repaint (hit testing uses live transforms; `onTop`
paint tracks scroll via compositing).

## Example app

Live demo: [https://hit-one-snowy.vercel.app/](https://hit-one-snowy.vercel.app/)

One-page demo covering `HitLayer`, `HitDefer`, common controls (chip dismiss, `Text.rich` / `WidgetSpan`, resize handle, window edge, list action, slider thumb), and Wrong vs Right for the common mistakes above:

```bash
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
