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

- Fix `Hit.defer(paintOnTop: true)` with scroll views: deferred paint uses a composited leader/follower so it tracks transforms without a full `HitScope` repaint.
- Fix disposed-layer crash when reusing `paintOnTop` follower layers across frames (`LayerHandle`).
- Expand example app with more demos (`Hit.before`, resize, window edge, chip, list, slider) and Cupertino UI.

## 0.1.0

- Initial release: `HitLayer`, `HitScope`, `Hit.defer` / `Hit.before`, and `HitLink`.
