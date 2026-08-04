#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT="$ROOT/hit_devtools_extension"
DEST="$ROOT/extension/devtools"

cd "$EXT"
flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest="$DEST"
dart run devtools_extensions validate --package="$ROOT"
echo "Built DevTools extension → $DEST/build"
