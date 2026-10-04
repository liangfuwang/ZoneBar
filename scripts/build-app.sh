#!/bin/zsh
# Build a release binary and wrap it into build/TimeBar.app (menu-bar only, no Dock icon).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --build-system native
BIN="$(swift build -c release --build-system native --show-bin-path)/TimeBar"

APP="build/TimeBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/TimeBar"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>com.timebar.app</string>
    <key>CFBundleName</key><string>TimeBar</string>
    <key>CFBundleExecutable</key><string>TimeBar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $APP"
