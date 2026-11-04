#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" && "$ARCH" != "x86_64" ]]; then
  printf 'Unsupported Mac architecture: %s\n' "$ARCH" >&2
  exit 1
fi
# Build outside iCloud/File Provider folders, which may attach Finder metadata
# while codesign is sealing an .app bundle. Deliver a ZIP back into the project.
STAGE_DIR="$(mktemp -d /private/tmp/xiexie-pet-build.XXXXXX)"
APP_DIR="$STAGE_DIR/蟹蟹桌宠.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$PROJECT_DIR/build/module-cache"
xcrun swiftc -swift-version 5 -target "$ARCH-apple-macos12.0" \
  -module-cache-path "$PROJECT_DIR/build/module-cache" \
  -O -framework AppKit -framework WebKit "$PROJECT_DIR/desktop/App.swift" \
  -o "$APP_DIR/Contents/MacOS/XiexiePet"
cp -X "$PROJECT_DIR/desktop/Info.plist" "$APP_DIR/Contents/Info.plist"
cp -X "$PROJECT_DIR/desktop/pet.html" "$PROJECT_DIR/desktop/pet.js" "$PROJECT_DIR/clawd-pool.js" \
  "$PROJECT_DIR/LICENSE" "$PROJECT_DIR/README.md" "$APP_DIR/Contents/Resources/"
cp -X "$PROJECT_DIR/desktop/README.md" "$APP_DIR/Contents/Resources/DESKTOP-README.md"
# Strip inherited Finder metadata from this generated bundle, never source files.
xattr -cr "$APP_DIR"
# Local development identity only, not an Apple notarization or release signature.
codesign --force --sign - "$APP_DIR"
codesign --verify --strict "$APP_DIR"
ditto -c -k --keepParent "$APP_DIR" "$PROJECT_DIR/build/蟹蟹桌宠.zip"
printf 'Built: %s\n' "$APP_DIR"
printf 'Archive: %s\n' "$PROJECT_DIR/build/蟹蟹桌宠.zip"
