#!/usr/bin/env bash
# Build the hit DevTools extension web app into extension/devtools/build.
#
# Size notes (see flutter/devtools#9897):
# - `devtools_extensions build_and_copy` hardcodes --no-tree-shake-icons and
#   ships the full local canvaskit/ tree even though flutter_bootstrap.js loads
#   CanvasKit from the gstatic CDN via engineRevision. We build ourselves with
#   icon tree-shaking and prune canvaskit/ after copy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT="$ROOT/hit_devtools_extension"
DEST="$ROOT/extension/devtools"
SRC_BUILD="$EXT/build/web"
DEST_BUILD="$DEST/build"

cd "$EXT"
flutter pub get

echo "Building extension (release, tree-shake-icons)..."
flutter build web \
  --pwa-strategy=offline-first \
  --release \
  --tree-shake-icons

echo "Copying build → $DEST_BUILD"
rm -rf "$DEST_BUILD"
mkdir -p "$DEST_BUILD"
cp -R "$SRC_BUILD"/. "$DEST_BUILD"/

# Drop local CanvasKit when the bootstrap is CDN-configured (default).
# Local files are never fetched at runtime in that case.
if [[ -f "$DEST_BUILD/flutter_bootstrap.js" ]] &&
  grep -q 'engineRevision' "$DEST_BUILD/flutter_bootstrap.js" &&
  ! grep -q 'useLocalCanvasKit":true\|"useLocalCanvasKit": true' "$DEST_BUILD/flutter_bootstrap.js"; then
  if [[ -d "$DEST_BUILD/canvaskit" ]]; then
    echo "Pruning unused local canvaskit/ (CDN via engineRevision)..."
    rm -rf "$DEST_BUILD/canvaskit"
  fi
fi

# Debug symbol maps are not needed at runtime.
find "$DEST_BUILD" -type f \( -name '*.js.symbols' -o -name '*.map' \) -delete

cd "$EXT"
dart run devtools_extensions validate --package="$ROOT"

echo "Built DevTools extension → $DEST_BUILD ($(du -sh "$DEST_BUILD" | cut -f1))"
