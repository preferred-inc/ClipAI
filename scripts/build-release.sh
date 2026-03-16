#!/bin/bash
set -euo pipefail

# ============================================================
# ClipAI Release Build Script
# Usage: ./scripts/build-release.sh [--sign] [--notarize]
# ============================================================

APP_NAME="ClipAI"
SCHEME="ClipAI"
PROJECT="ClipAI.xcodeproj"
BUILD_DIR="build/release"
DMG_NAME="${APP_NAME}.dmg"
VERSION=$(defaults read "$(pwd)/ClipAI/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

SIGN=false
NOTARIZE=false
DEVELOPER_ID=""        # e.g., "Developer ID Application: Your Name (TEAM_ID)"
APPLE_ID=""            # Apple ID for notarization
TEAM_ID=""             # Team ID
APP_PASSWORD=""        # App-specific password for notarization

# Parse arguments
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

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build
xcodebuild -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/derived" \
    SYMROOT="${BUILD_DIR}" \
    clean build 2>&1 | tail -5

APP_PATH="${BUILD_DIR}/Release/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Build failed - app not found at ${APP_PATH}"
    exit 1
fi

echo "✅ Build succeeded"

# Code signing
if [ "$SIGN" = true ]; then
    if [ -z "$DEVELOPER_ID" ]; then
        # Try to find Developer ID automatically
        DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
    fi

    if [ -z "$DEVELOPER_ID" ]; then
        echo "❌ No Developer ID found. Install your certificate or specify --developer-id="
        exit 1
    fi

    echo "🔏 Signing with: ${DEVELOPER_ID}"

    codesign --force --deep --options runtime \
        --sign "${DEVELOPER_ID}" \
        --entitlements "ClipAI/ClipAI.entitlements" \
        "${APP_PATH}"

    # Verify
    codesign --verify --verbose "${APP_PATH}"
    echo "✅ Code signing verified"
fi

# Create DMG
echo "📦 Creating DMG..."

DMG_TEMP="${BUILD_DIR}/${APP_NAME}-temp.dmg"
DMG_FINAL="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"
DMG_VOLUME="/Volumes/${APP_NAME}"

# Create temporary DMG
hdiutil create -size 100m -fs HFS+ -volname "${APP_NAME}" "${DMG_TEMP}" -ov

# Mount
hdiutil attach "${DMG_TEMP}" -mountpoint "${DMG_VOLUME}"

# Copy app
cp -R "${APP_PATH}" "${DMG_VOLUME}/"

# Create Applications symlink
ln -s /Applications "${DMG_VOLUME}/Applications"

# Set icon positions using AppleScript
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 900, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {120, 160}
        set position of item "Applications" of container window to {380, 160}
        close
    end tell
end tell
APPLESCRIPT

# Unmount
sync
hdiutil detach "${DMG_VOLUME}"

# Convert to compressed DMG
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"
rm -f "${DMG_TEMP}"

echo "✅ DMG created: ${DMG_FINAL}"

# Notarize
if [ "$NOTARIZE" = true ]; then
    if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
        echo "❌ Notarization requires --apple-id, --team-id, and --app-password"
        exit 1
    fi

    echo "📤 Submitting for notarization..."

    xcrun notarytool submit "${DMG_FINAL}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${TEAM_ID}" \
        --password "${APP_PASSWORD}" \
        --wait

    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "${DMG_FINAL}"

    echo "✅ Notarization complete"
fi

# Summary
echo ""
echo "================================================"
echo "  ${APP_NAME} v${VERSION} Release Build"
echo "================================================"
echo "  App: ${APP_PATH}"
echo "  DMG: ${DMG_FINAL}"
echo "  Size: $(du -sh "${DMG_FINAL}" | cut -f1)"
if [ "$SIGN" = true ]; then
    echo "  Signed: ✅"
fi
if [ "$NOTARIZE" = true ]; then
    echo "  Notarized: ✅"
fi
echo "================================================"
