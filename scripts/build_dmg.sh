#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="PasteClone"
VERSION="${VERSION:-1.3.2}"
DERIVE_DATA="$BUILD_DIR/DerivedData-$VERSION"
DMG_PATH="$BUILD_DIR/PasteClone-$VERSION.dmg"
ZIP_PATH="$BUILD_DIR/PasteClone-$VERSION.zip"
TEMP_DMG="$(mktemp -u /tmp/PasteClone-temp.XXXXXX).dmg"
trap 'rm -f "$TEMP_DMG"' EXIT

xcodebuild -project "$PROJECT_DIR/PasteClone.xcodeproj" -scheme PasteClone -configuration Release -sdk macosx \
  -derivedDataPath "$DERIVE_DATA" -arch arm64 -arch x86_64 build \
  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO >/dev/null
APP_PATH="$DERIVE_DATA/Build/Products/Release/$APP_NAME.app"
test -d "$APP_PATH"
mkdir -p "$BUILD_DIR"
rm -f "$DMG_PATH" "$ZIP_PATH"
hdiutil create -srcfolder "$APP_PATH" -volname "$APP_NAME" -fs HFS+ -format UDRW -o "$TEMP_DMG" >/dev/null
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH" >/dev/null
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Created $DMG_PATH and $ZIP_PATH"
file "$APP_PATH/Contents/MacOS/$APP_NAME"
