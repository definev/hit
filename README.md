# hit

Separate **paint/layout size** from **hit size** in Flutter, and deliver taps that fall outside a widget’s layout box.

Use it when a control must stay visually small (icon, grip, 1px edge, chip ×) but still meet a comfortable / WCAG touch target without pushing neighbors.

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
  hit: ^0.1.0
```

```dart
import 'package:hit/hit.dart';
```

## Quick start

Minimum icon with a 48×48 hit target — layout stays 24×24:

```dart
HitScope(
  child: HitLayer(
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
)
```

Wrap a **tight** ancestor in `HitScope` whenever `hitChild` overflows `paintChild`. Without it, overflow corners never receive events.

## API

### `HitLayer`

Two-child render object:

- **`paintChild`** — visual layer; defines layout size
- **`hitChild`** — gesture / hover layer; may be larger
- **`alignment`** — where paint sits inside the hit box (`Alignment.center` by default)
- **`behavior`** — how paint and hit interact (`HitTestBehavior`)
- **`link`** — optional `HitLink`; defaults to the nearest `HitScope`

When `hitChild` overflows layout, the layer registers on the link and local `hitTest` returns `false` so Flutter does not clip overflow away. Hits are delivered through `HitScope`.

Non-overflowing layers stay on the normal local hit path and do **not** register.

### `HitScope`

Ancestor that hit-tests (and optionally paints) deferred targets.

```dart
HitScope(
  // link: myLink, // optional shared HitLink
  child: /* … */,
)
```

- Nesting is supported; **nearest** scope wins (`HitScope.maybeOf` / `of`).
- Prefer many small scopes over one app-wide scope.
- Pass an explicit `link` to register with an outer scope instead of the nearest one.

`RenderHitScope` does not clip deferred hits to its own size, but intermediate parents (`ClipRect`, tight boxes that reject outside hits) above the scope can still block the walk.

### `Hit.defer` / `Hit.before`

For widgets that hang outside a parent without using `HitLayer`:

```dart
HitScope(
  child: SizedBox(
    width: 100,
    height: 100,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: -20,
          child: Hit.defer(
            child: GestureDetector(
              onTap: onBadgeTap,
              child: const Badge(),
            ),
          ),
        ),
        // …
      ],
    ),
  ),
)
```

- `Hit.defer` — deferred hit; optional `paintOnTop: true` to paint after the scoped subtree
- `Hit.before` — deferred hit and paint **under** the scoped subtree

Local `hitTest` is always `false`; delivery is only via the scope.

### `HitTestBehavior`

| Value | Meaning |
| --- | --- |
| `translucent` | Test paint and hit when both overlap |
| `deferToChild` | Prefer paint; hit only if paint missed |
| `opaque` | Same as defer for the layer; a deferred opaque hit stops scanning further deferred targets in the scope |

### `HitLink`

Registry of deferred targets for a scope. Usually owned by `HitScope`; pass explicitly to share or target a non-nearest scope.

## Performance notes

Deferred hit-testing is **O(n)** over registered targets on that scope (AABB cached per hit-test pass; transforms are recomputed so scroll stays correct). To keep it fast:

1. Keep `HitScope` tight around overflow regions
2. Prefer non-overflowing `HitLayer` when the hit fits in paint size (no registration)
3. Prefer `deferToChild` / `opaque` over `translucent` when you do not need dual hits
4. Keep `hitChild` shallow (`GestureDetector` + `SizedBox`)
5. Avoid nesting deferred targets under one huge root scope
6. Use `Hit.defer` only when you need out-of-bounds delivery

A handful of min-target / edge / handle layers is cheap. Hundreds of deferred targets under one scope is not.

## Example

One-page demo covering `HitLayer` (small paint / large hit) and `Hit.defer` (overflow control):

```bash
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
