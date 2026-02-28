#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
APP_NAME="in254 Launcher"
BUNDLE_DIR="$PROJECT_DIR/bin/publish/${APP_NAME}.app"
RID="${1:-osx-arm64}"

echo "==> Publishing for $RID..."
dotnet publish "$PROJECT_DIR/Launcher.csproj" -c Release -r "$RID" --self-contained

PUBLISH_DIR="$PROJECT_DIR/bin/Release/net10.0/$RID/publish"

# --- Generate Icon.icns from Icon.ico ---
echo "==> Generating Icon.icns..."
ICO_FILE="$PROJECT_DIR/Assets/Icon.ico"
ICONSET_DIR="$(mktemp -d)/Icon.iconset"
mkdir -p "$ICONSET_DIR"

# Extract the largest PNG from the .ico file
TEMP_PNG="$(mktemp).png"
sips -s format png "$ICO_FILE" --out "$TEMP_PNG" >/dev/null 2>&1

# Generate all required sizes for the iconset
for SIZE in 16 32 128 256 512; do
    sips -z $SIZE $SIZE "$TEMP_PNG" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" >/dev/null 2>&1
    DOUBLE=$((SIZE * 2))
    if [ $DOUBLE -le 1024 ]; then
        sips -z $DOUBLE $DOUBLE "$TEMP_PNG" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" >/dev/null 2>&1
    fi
done

ICNS_FILE="$PROJECT_DIR/Assets/Icon.icns"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
rm -rf "$(dirname "$ICONSET_DIR")" "$TEMP_PNG"
echo "    Created $ICNS_FILE"

# --- Assemble .app bundle ---
echo "==> Assembling ${APP_NAME}.app..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$PROJECT_DIR/macOS/Info.plist" "$BUNDLE_DIR/Contents/"
cp "$ICNS_FILE" "$BUNDLE_DIR/Contents/Resources/"
cp -R "$PUBLISH_DIR"/* "$BUNDLE_DIR/Contents/MacOS/"

# Ensure the main executable is runnable
chmod +x "$BUNDLE_DIR/Contents/MacOS/Launcher"

echo "==> Done! App bundle at:"
echo "    $BUNDLE_DIR"
