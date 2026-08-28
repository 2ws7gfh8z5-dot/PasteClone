#!/bin/bash
set -euo pipefail
REPO="2ws7gfh8z5-dot/PasteClone"
VERSION="${1:-1.3.3}"
BUILD_DIR="$(cd "$(dirname "$0")/../build" && pwd)"
NOTES="$(cd "$(dirname "$0")/.." && sed -n "/^## \\[$VERSION\\]/,/^## \\[/p" CHANGELOG.md | sed '$d')"
if [ -z "$NOTES" ]; then NOTES="PasteClone v$VERSION"; fi
gh release create "v$VERSION" "$BUILD_DIR/PasteClone-$VERSION.dmg" "$BUILD_DIR/PasteClone-$VERSION.zip" \
  --repo "$REPO" --title "PasteClone v$VERSION" --notes "$NOTES"
