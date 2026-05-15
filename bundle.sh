#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# bundle.sh — Build PixelDrop and wrap it in a real macOS .app bundle
#
# Why? `swift build` produces a plain Mach-O executable. macOS launches plain
# binaries as background processes — no Dock icon, no window. A proper .app
# bundle gives you all the normal macOS app behaviour.
#
# Usage:
#   ./bundle.sh                   # release build, opens the .app
#   ./bundle.sh --debug           # debug build
#   ./bundle.sh --no-launch       # build only, don't open
# ─────────────────────────────────────────────────────────────────────────────

set -e

CONFIG="release"
LAUNCH=true

for arg in "$@"; do
    case "$arg" in
        --debug)     CONFIG="debug" ;;
        --no-launch) LAUNCH=false ;;
    esac
done

APP_NAME="PixelDrop"
BUNDLE_ID="com.osmansezer.pixeldrop"
VERSION="1.0.0"
BUILD="1"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "▶ Building ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$BUILD_DIR/$CONFIG/$APP_NAME"
if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Build output not found at $BIN_PATH"
    exit 1
fi

echo "▶ Creating $APP_NAME.app bundle…"

# Clean any previous bundle
rm -rf "$APP_DIR"

# Standard macOS app bundle layout:
#   PixelDrop.app/
#     Contents/
#       Info.plist
#       MacOS/PixelDrop          ← executable
#       Resources/
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy the binary
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Generate Info.plist — this is what tells macOS "I'm a real app, give me a window"
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>            <string>en</string>
    <key>CFBundleDisplayName</key>                  <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>                   <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>                   <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>        <string>6.0</string>
    <key>CFBundleName</key>                         <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>                  <string>APPL</string>
    <key>CFBundleShortVersionString</key>           <string>$VERSION</string>
    <key>CFBundleVersion</key>                      <string>$BUILD</string>
    <key>LSMinimumSystemVersion</key>               <string>13.0</string>
    <key>LSApplicationCategoryType</key>            <string>public.app-category.graphics-design</string>
    <key>NSHighResolutionCapable</key>              <true/>
    <key>NSPrincipalClass</key>                     <string>NSApplication</string>
    <key>NSSupportsAutomaticTermination</key>       <true/>
    <key>NSSupportsSuddenTermination</key>          <true/>

    <!-- Tell macOS this app handles image files (so File > Open works nicely) -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>             <string>Image</string>
            <key>CFBundleTypeRole</key>             <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.image</string>
                <string>public.heic</string>
                <string>public.jpeg</string>
                <string>public.png</string>
                <string>public.tiff</string>
                <string>public.camera-raw-image</string>
                <string>org.openexr.exr-image</string>
                <string>public.avif</string>
                <string>public.webp</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "✅ Built: $APP_DIR"
echo "   Size: $(du -sh "$APP_DIR" | cut -f1)"

if [ "$LAUNCH" = true ]; then
    echo ""
    echo "▶ Launching $APP_NAME…"
    open "$APP_DIR"
fi

echo ""
echo "💡 To install permanently:"
echo "   cp -R \"$APP_DIR\" /Applications/"
