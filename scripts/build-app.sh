#!/bin/zsh
# Build a release binary and wrap it into build/ZoneBar.app (menu-bar only, no Dock icon).
# Usage: VERSION=1.0.0 BUILD=1 ./scripts/build-app.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-1}"

swift build -c release --build-system native
BIN="$(swift build -c release --build-system native --show-bin-path)/ZoneBar"

APP="build/ZoneBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ZoneBar"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleIdentifier</key><string>xyz.liangfuwang.ZoneBar</string>
    <key>CFBundleName</key><string>ZoneBar</string>
    <key>CFBundleDisplayName</key><string>ZoneBar</string>
    <key>CFBundleExecutable</key><string>ZoneBar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Copyright © 2026 liangfuwang. Released under the MIT License.</string>
</dict>
</plist>
EOF

plutil -lint "$APP/Contents/Info.plist" >/dev/null
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $APP (v$VERSION)"
