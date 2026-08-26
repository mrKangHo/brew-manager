#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-1.0.0}"
APP_NAME="Brew Manager"
BUNDLE_ID="com.mrkanho.brewmanager"

echo "Building release binary..."
swift build -c release

BUILD_DIR=".build/release"
BINARY="$BUILD_DIR/HomeBrewInstaller"
RESOURCE_BUNDLE="$BUILD_DIR/HomeBrewInstaller_HomeBrewInstaller.bundle"

if [ ! -f "$BINARY" ]; then
  echo "error: binary not found at $BINARY"
  exit 1
fi

APP_DIR="dist/$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BINARY" "$APP_DIR/Contents/MacOS/HomeBrewInstaller"
if [ -d "$RESOURCE_BUNDLE" ]; then
  cp -R "$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/"
fi
cp AppResources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

sed "s/1.0.0/$VERSION/" dist/Info.plist > "$APP_DIR/Contents/Info.plist"

echo "Ad-hoc signing..."
codesign --force --deep -s - "$APP_DIR"

ZIP_PATH="dist/BrewManager-macOS-$VERSION.zip"
rm -f "$ZIP_PATH"
(cd dist && zip -qry "$(basename "$ZIP_PATH")" "$APP_NAME.app")

echo "Built: $APP_DIR"
echo "Zipped: $ZIP_PATH"
