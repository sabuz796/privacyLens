#!/bin/bash
# Builds PrivacyLens and packages a distributable PrivacyLens.zip
# ready to attach to a GitHub Release.
#
# Usage: ./Scripts/package_release.sh [Release|Debug]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Release}"
APP_NAME="PrivacyLens"
APP="build.noindex/$CONFIG/$APP_NAME.app"
ZIP="$APP_NAME.zip"

echo "==> Building ($CONFIG)…"
if ! xcodebuild -project "$APP_NAME.xcodeproj" -target "$APP_NAME" \
      -configuration "$CONFIG" build | grep -q "BUILD SUCCEEDED"; then
    echo "❌ Build failed — run again without piping to see errors."
    exit 1
fi

echo "==> Verifying code signature…"
codesign --verify --strict "$APP"
codesign -dvv "$APP" 2>&1 | grep -E "Authority|Identifier=" | sed 's/^/    /'

echo "==> Zipping (ditto preserves signature and metadata)…"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> SHA-256 (put this in the release notes):"
shasum -a 256 "$ZIP" | sed 's/^/    /'

echo "✅ Done: $ZIP — attach it to your GitHub Release."
