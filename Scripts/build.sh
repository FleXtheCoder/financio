#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
BUILD_DIR="$ROOT/.build"
APP_DIR="$ROOT/dist/Financio.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "→ Building Financio ($CONFIG)…"
swift build -c "$CONFIG" --product Financio

BIN="$BUILD_DIR/$CONFIG/Financio"
if [[ ! -x "$BIN" ]]; then
  echo "Build-Artefakt nicht gefunden: $BIN" >&2
  exit 1
fi

echo "→ Erstelle App-Bundle…"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN" "$MACOS_DIR/Financio"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
chmod +x "$MACOS_DIR/Financio"

# Leeres PkgInfo für klassische App-Bundles
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

echo "✓ Fertig: $APP_DIR"
echo "  Starten mit: open \"$APP_DIR\""
