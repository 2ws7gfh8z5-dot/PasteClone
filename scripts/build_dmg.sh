#!/bin/bash
set -e

PROJECT_DIR="/Users/huaziyi/Desktop/pasteclone"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="PasteClone"
DERIVE_DATA="$BUILD_DIR/DerivedData"
DMG_PATH="$BUILD_DIR/PasteClone-1.2.2.dmg"
ZIP_PATH="$BUILD_DIR/PasteClone-1.2.2.zip"
TEMP_DMG="$(mktemp -u /tmp/PasteClone-temp.XXXXXX).dmg"
trap 'rm -f "$TEMP_DMG"' EXIT

echo "🔨 Building Release..."
xcodebuild -project "$PROJECT_DIR/PasteClone.xcodeproj" \
    -scheme PasteClone \
    -configuration Release \
    -sdk macosx \
    -derivedDataPath "$DERIVE_DATA" \
    build CODE_SIGNING_ALLOWED=NO > /dev/null 2>&1

APP_PATH="$DERIVE_DATA/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed: app not found"
    exit 1
fi

echo "📦 Creating DMG..."
mkdir -p "$BUILD_DIR"
rm -f "$DMG_PATH" "$ZIP_PATH"

# 创建DMG
hdiutil create -srcfolder "$APP_PATH" -volname "$APP_NAME" \
    -fs HFS+ -format UDRW -o "$TEMP_DMG" > /dev/null 2>&1

# 转换为压缩格式
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH" > /dev/null 2>&1
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "✅ DMG created: $DMG_PATH"
ls -lh "$DMG_PATH" "$ZIP_PATH"
