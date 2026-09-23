#!/bin/bash
# Builds PrivacyLens and packages a distributable PrivacyLens.dmg
# ready to attach to a GitHub Release.
#
# Usage: ./Scripts/package_release.sh [Release|Debug]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Release}"
APP_NAME="PrivacyLens"
APP="build.noindex/$CONFIG/$APP_NAME.app"
DMG="$APP_NAME.dmg"
STAGE="build.noindex/dmg-staging"

echo "==> Building ($CONFIG)…"
if ! xcodebuild -project "$APP_NAME.xcodeproj" -target "$APP_NAME" \
      -configuration "$CONFIG" build | grep -q "BUILD SUCCEEDED"; then
    echo "❌ Build failed — run again without piping to see errors."
    exit 1
fi

echo "==> Verifying code signature…"
codesign --verify --strict "$APP"
codesign -dvv "$APP" 2>&1 | grep -E "Authority|Identifier=" | sed 's/^/    /'

echo "==> Creating DMG (drag-to-Applications layout)…"
rm -f "$DMG"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "==> SHA-256 (put this in the release notes):"
shasum -a 256 "$DMG" | sed 's/^/    /'

echo "✅ Done: $DMG — attach it to your GitHub Release."
