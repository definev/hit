<p align="center">
  <img src="https://raw.githubusercontent.com/definev/hit/main/assets/banner.png" alt="hit — expand touch targets without growing layout" />
</p>

Separate **paint/layout size** from **hit size** in Flutter, and deliver taps that fall outside a widget’s layout box.

Use it when a control must stay visually small (icon, grip, 1px edge, chip ×) but still meet a comfortable / WCAG touch target without pushing neighbors.

**Live demo:** [hit-one-snowy.vercel.app](https://hit-one-snowy.vercel.app/)

Deferred out-of-bounds hit testing is inspired by [`defer_pointer`](https://pub.dev/packages/defer_pointer) ([gskinnerTeam/flutter-defer-pointer](https://github.com/gskinnerTeam/flutter-defer-pointer)): a handler higher in the tree (`HitScope`) receives hits for targets that opt out of local hit-testing (`Hit.defer` / overflowing `HitLayer`).

## Why

Flutter layout and hit-testing share the same box. Growing padding to enlarge a tap target also grows layout. Overflowing a child past its parent usually **stops receiving hits**.

`hit` splits those concerns:

| Piece | Role |
| --- | --- |
| `HitLayer` | Layout follows `paintChild`; `hitChild` can be larger and overflow |
| `HitScope` | Delivers overflow / out-of-bounds hits to registered targets |
| `Hit.defer` / `Hit.before` | Explicit deferred hit (and optional paint) outside parent bounds |

## Install

```yaml
dependencies:
  hit: ^1.0.0
```

```dart
import 'package:flutter/material.dart';
import 'package:hit/hit.dart';
```

## Supported API

Stable surface from `package:hit/hit.dart`:

- `HitLayer`, `HitScope` / `HitScopeState`
- `Hit.defer` / `Hit.before`
- `HitLink`, `HitDeferRegistration`

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

Overflowing `HitLayer` and `Hit.defer` / `Hit.before` need a scope (or an explicit `HitLink` wired to one). Without it, only the layout box is hittable; debug builds assert.

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
| Scroll paint lag with `Hit.before` | Scope repaint path | Prefer `Hit.defer(paintOnTop: true)` |

## API

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

- Nesting is supported; **nearest** scope wins (`HitScope.maybeOf` / `of`).
- Prefer many small scopes over one app-wide scope — but each scope’s **layout box must cover** the deferred hit areas it serves.
- Pass an explicit `link` to register with an outer scope instead of the nearest one.
- `HitScope.of` throws a `FlutterError` when no scope is found; use `maybeOf` when absence is allowed.

Deferred hit walk order is **newest-first**.

### `Hit.defer` / `Hit.before`

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
            child: Hit.defer(
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

- `Hit.defer` — deferred hit; optional `paintOnTop: true` to paint after the scoped subtree (tracks scroll via compositing)
- `Hit.before` — deferred hit and paint **under** the scoped subtree (prefer `paintOnTop` when you need composited scroll tracking)
- `behavior` defaults to `translucent`; use `opaque` when a hit should stop further deferred scanning **and** skip the scoped subtree

### `HitTestBehavior`

Defaults differ by API and are intentional:

| API | Default |
| --- | --- |
| `HitLayer` | `opaque` |
| `Hit.defer` / `Hit.before` | `translucent` |

| Value | Meaning |
| --- | --- |
| `translucent` | On `HitLayer`: test paint and hit when both overlap. On deferred targets: hit and still walk the scoped subtree |
| `deferToChild` | Prefer paint; hit only if paint missed (`HitLayer`) |
| `opaque` | On `HitLayer`: same as defer for paint vs hit. On deferred targets: stop further deferred scanning **and** skip the scoped subtree |

### `HitLink`

Registry of deferred targets for a scope. Usually owned by `HitScope`; pass explicitly to share or target a non-nearest scope. `HitDeferRegistration` is the extension contract implemented by deferred targets.

## Performance notes

Deferred hit-testing is **O(n)** over registered targets on that scope. To keep it fast:

1. Keep `HitScope` tight around overflow regions — but still large enough to cover them
2. Prefer non-overflowing `HitLayer` when the hit fits in paint size (no registration)
3. Prefer `deferToChild` / `opaque` over `translucent` when you do not need dual hits
4. Keep `hitChild` shallow (`GestureDetector` + `SizedBox`)
5. Avoid nesting deferred targets under one huge root scope
6. Use `Hit.defer` only when you need out-of-bounds delivery

A handful of min-target / edge / handle layers is cheap. Hundreds of deferred targets under one scope is not.

## Example

Live demo: [https://hit-one-snowy.vercel.app/](https://hit-one-snowy.vercel.app/)

One-page demo covering `HitLayer`, `Hit.defer` / `Hit.before`, common controls (chip dismiss, resize handle, window edge, list action, slider thumb), and Wrong vs Right for the common mistakes above:

```bash
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
