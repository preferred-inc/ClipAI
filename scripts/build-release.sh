#!/bin/bash
set -euo pipefail

# ============================================================
# ClipAI Release Build Script
# Usage: ./scripts/build-release.sh [--sign] [--notarize]
# ============================================================

APP_NAME="ClipAI"
SCHEME="ClipAI"
PROJECT="ClipAI.xcodeproj"
BUILD_DIR="build"
VERSION="1.0.0"

SIGN=false
NOTARIZE=false
DEVELOPER_ID=""
APPLE_ID=""
TEAM_ID=""
APP_PASSWORD=""

for arg in "$@"; do
    case $arg in
        --sign) SIGN=true ;;
        --notarize) NOTARIZE=true; SIGN=true ;;
        --developer-id=*) DEVELOPER_ID="${arg#*=}" ;;
        --apple-id=*) APPLE_ID="${arg#*=}" ;;
        --team-id=*) TEAM_ID="${arg#*=}" ;;
        --app-password=*) APP_PASSWORD="${arg#*=}" ;;
    esac
done

echo "🔨 Building ${APP_NAME} v${VERSION}..."

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/derived" \
    build 2>&1 | tail -3

APP_PATH="${BUILD_DIR}/derived/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Build failed"
    exit 1
fi
echo "✅ Build succeeded"

# Code signing
if [ "$SIGN" = true ]; then
    if [ -z "$DEVELOPER_ID" ]; then
        DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
    fi
    if [ -z "$DEVELOPER_ID" ]; then
        echo "❌ No Developer ID found"
        exit 1
    fi
    echo "🔏 Signing with: ${DEVELOPER_ID}"
    codesign --force --deep --options runtime \
        --sign "${DEVELOPER_ID}" \
        "${APP_PATH}"
    codesign --verify --verbose "${APP_PATH}"
    echo "✅ Signed"
fi

# Create DMG
echo "📦 Creating DMG..."

DMG_TEMP="${BUILD_DIR}/${APP_NAME}-temp.dmg"
DMG_FINAL="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"

hdiutil create -size 100m -fs HFS+ -volname "${APP_NAME}" "${DMG_TEMP}" -ov -quiet
hdiutil attach "${DMG_TEMP}" -mountpoint "/Volumes/${APP_NAME}" -quiet

cp -R "${APP_PATH}" "/Volumes/${APP_NAME}/"
ln -s /Applications "/Volumes/${APP_NAME}/Applications"

# Layout
osascript <<'APPLESCRIPT'
tell application "Finder"
    tell disk "ClipAI"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 880, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "ClipAI.app" of container window to {110, 140}
        set position of item "Applications" of container window to {370, 140}
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "/Volumes/${APP_NAME}" -quiet
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}" -quiet
rm -f "${DMG_TEMP}"

echo "✅ DMG: ${DMG_FINAL} ($(du -sh "${DMG_FINAL}" | cut -f1))"

# Notarize
if [ "$NOTARIZE" = true ]; then
    if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
        echo "❌ Need --apple-id, --team-id, --app-password"
        exit 1
    fi
    echo "📤 Notarizing..."
    xcrun notarytool submit "${DMG_FINAL}" \
        --apple-id "${APPLE_ID}" --team-id "${TEAM_ID}" --password "${APP_PASSWORD}" --wait
    xcrun stapler staple "${DMG_FINAL}"
    echo "✅ Notarized"
fi

echo ""
echo "  ${APP_NAME} v${VERSION} — ${DMG_FINAL}"
