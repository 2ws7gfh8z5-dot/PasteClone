#!/bin/bash
set -euo pipefail
REPO="2ws7gfh8z5-dot/PasteClone"
VERSION="${1:-1.7.0}"
BUILD_DIR="$(cd "$(dirname "$0")/../dist" && pwd)"
NOTES="$(cd "$(dirname "$0")/.." && sed -n "/^## \\[$VERSION\\]/,/^## \\[/p" CHANGELOG.md | sed '$d')"
if [ -z "$NOTES" ]; then NOTES="PasteClone v$VERSION"; fi
gh release create "v$VERSION" "$BUILD_DIR/JustPaste-$VERSION-macos-universal.dmg" "$BUILD_DIR/JustPaste-$VERSION-macos-universal.zip" \
  --repo "$REPO" --title "PasteClone v$VERSION" --notes "$NOTES"
