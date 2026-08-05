# hit_devtools_extension

Flutter web app for the **hit** [DevTools extension](https://pub.dev/packages/devtools_extensions).

Source lives here so it does not inflate `package:hit` for app users. Built
assets are copied into `../extension/devtools/build` and shipped with the
published package.

`../tool/build_devtools.sh` builds with icon tree-shaking and strips the local
`canvaskit/` directory (CanvasKit is loaded from the Flutter CDN via
`engineRevision` in `flutter_bootstrap.js`). Prefer that script over
`dart run devtools_extensions build_and_copy`, which ships ~40 MB of unused
engine binaries (see [flutter/devtools#9897](https://github.com/flutter/devtools/issues/9897)).

## Develop

```bash
# Simulated DevTools shell (hot reload):
flutter run -d chrome --dart-define=use_simulated_environment=true

# Build into package:hit for path / pub publish:
../tool/build_devtools.sh
```

Connect a debug Flutter app that depends on `package:hit` (for example
`../example`) and open the **hit** tab in DevTools.
