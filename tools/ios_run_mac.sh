#!/bin/bash
# Builds Ray Ağı for iOS on a Mac and installs it on a connected iPhone.
#
#   ./tools/ios_run_mac.sh <APPLE_TEAM_ID> [bundle_id]
#
# Requirements: macOS, Xcode 15+ (signed in with your Apple ID under Settings → Accounts),
# iPhone connected by USB/Wi-Fi with Developer Mode enabled (Settings → Privacy & Security).
set -euo pipefail

TEAM_ID="${1:?Usage: $0 <APPLE_TEAM_ID> [bundle_id]}"
BUNDLE_ID="${2:-com.rayagi.metro}"
GODOT_VERSION="4.3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="$HOME/.cache/rayagi"
GODOT_APP="$CACHE/Godot.app"
GODOT="$GODOT_APP/Contents/MacOS/Godot"
TPL_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
OUT="$ROOT/build/ios"

mkdir -p "$CACHE" "$OUT"

# 1) Godot editor
if [ ! -x "$GODOT" ]; then
  echo "==> Downloading Godot $GODOT_VERSION"
  curl -L -o "$CACHE/godot.zip" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip"
  (cd "$CACHE" && unzip -q -o godot.zip)
fi

# 2) Export templates (contains the iOS template)
if [ ! -f "$TPL_DIR/ios.zip" ]; then
  echo "==> Downloading export templates (~1 GB)"
  curl -L -o "$CACHE/tpl.tpz" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
  rm -rf "$CACHE/tpl" && mkdir -p "$CACHE/tpl" "$TPL_DIR"
  (cd "$CACHE/tpl" && unzip -q "$CACHE/tpl.tpz")
  cp -R "$CACHE/tpl/templates/"* "$TPL_DIR/"
fi

# 3) Put the team id / bundle id into a temporary copy of the export preset
cd "$ROOT"
cp export_presets.cfg "$CACHE/export_presets.backup.cfg"
trap 'cp "$CACHE/export_presets.backup.cfg" "$ROOT/export_presets.cfg"' EXIT
sed -i '' "s|application/app_store_team_id=\".*\"|application/app_store_team_id=\"$TEAM_ID\"|" export_presets.cfg
sed -i '' "s|application/bundle_identifier=\".*\"|application/bundle_identifier=\"$BUNDLE_ID\"|" export_presets.cfg
sed -i '' "s|application/export_project_only=false|application/export_project_only=true|" export_presets.cfg

# 4) Import + export the Xcode project
echo "==> Importing project"
"$GODOT" --headless --path . --import || true
echo "==> Exporting Xcode project"
"$GODOT" --headless --path . --export-debug "iOS" "$OUT/RayAgi.ipa"
PROJ="$(ls -d "$OUT"/*.xcodeproj | head -1)"
SCHEME="$(basename "$PROJ" .xcodeproj)"
echo "    $PROJ"

# 5) Find the connected iPhone
DEVICE_ID="$(xcrun xctrace list devices 2>/dev/null | grep -E 'iPhone' | grep -v Simulator | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{20,})\)$/\1/')"
if [ -z "$DEVICE_ID" ]; then
  echo "No iPhone found. Connect it, unlock it, trust this Mac and enable Developer Mode."
  open "$PROJ"
  exit 1
fi
echo "==> Building for device $DEVICE_ID"
xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$DEVICE_ID" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" CODE_SIGN_STYLE=Automatic \
  -derivedDataPath "$OUT/DerivedData" build

APP="$(find "$OUT/DerivedData/Build/Products" -name '*.app' -maxdepth 3 | head -1)"
echo "==> Installing $APP"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" || true
echo "==> Done. If iOS says 'Untrusted Developer': Settings → General → VPN & Device Management → trust your Apple ID."
