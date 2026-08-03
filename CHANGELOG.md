## 0.2.0

- Fix `Hit.defer(paintOnTop: true)` with scroll views: deferred paint uses a composited leader/follower so it tracks transforms without a full `HitScope` repaint.
- Fix disposed-layer crash when reusing `paintOnTop` follower layers across frames (`LayerHandle`).
- Expand example app with more demos (`Hit.before`, resize, window edge, chip, list, slider) and Cupertino UI.

## 0.1.0

- Initial release: `HitLayer`, `HitScope`, `Hit.defer` / `Hit.before`, and `HitLink`.
