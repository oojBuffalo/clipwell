#!/usr/bin/env bash
set -euo pipefail

mode="${1:-run}"
case "$mode" in
  run|--debug|--logs|--telemetry|--verify) ;;
  *) echo "Usage: $0 [--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."
bundle="$(pwd -P)/dist/Clipwell.app"
contents="$bundle/Contents"
executable="$contents/MacOS/Clipwell"
bundle_id="app.clipwell.Clipwell"

workspace_app_pids() {
  local pid
  while read -r pid; do
    if [[ "$(ps -ww -p "$pid" -o comm=)" == "$executable" ]]; then
      echo "$pid"
    fi
  done < <(pgrep -x Clipwell || true)
}

while read -r pid; do
  kill "$pid" 2>/dev/null || true
done < <(workspace_app_pids)

swift build --product Clipwell
binary_dir="$(swift build --show-bin-path)"
mkdir -p "$contents/MacOS" "$contents/Resources"
install -m 755 "$binary_dir/Clipwell" "$executable"
install -m 644 Resources/AppIcon.icns "$contents/Resources/AppIcon.icns"

cat > "$contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Clipwell</string>
  <key>CFBundleIdentifier</key><string>$bundle_id</string>
  <key>CFBundleName</key><string>Clipwell</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --sign - --identifier "$bundle_id" "$bundle"
if [[ "$mode" == "--debug" ]]; then
  exec lldb -- "$executable"
fi

/usr/bin/open -n "$bundle"
case "$mode" in
  --verify)
    sleep 1
    if [[ -z "$(workspace_app_pids)" ]]; then
      echo "Clipwell exited after launch." >&2
      exit 1
    fi
    echo "Running $bundle"
    ;;
  --logs) exec /usr/bin/log stream --info --style compact --predicate 'process == "Clipwell"' ;;
  --telemetry) exec /usr/bin/log stream --info --style compact --predicate "subsystem == \"$bundle_id\"" ;;
esac
