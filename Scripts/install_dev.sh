#!/bin/bash
# Dev loop: rebuild, refresh the installed app in /Applications, launch.
# FDA grants persist across runs because the signature is stable
# ("PrivacyLens Dev" certificate — do not switch back to ad-hoc).
#
# Usage: ./Scripts/install_dev.sh [Debug|Release]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Debug}"
APP_NAME="PrivacyLens"

echo "==> Building ($CONFIG)…"
if ! xcodebuild -project "$APP_NAME.xcodeproj" -target "$APP_NAME" \
      -configuration "$CONFIG" build | grep -q "BUILD SUCCEEDED"; then
    echo "❌ Build failed — run again without piping to see errors."
    exit 1
fi

echo "==> Refreshing /Applications/$APP_NAME.app…"
killall "$APP_NAME" 2>/dev/null || true
ditto "build.noindex/$CONFIG/$APP_NAME.app" "/Applications/$APP_NAME.app"

echo "==> Launching…"
open "/Applications/$APP_NAME.app"

echo "✅ Installed and launched: /Applications/$APP_NAME.app"
