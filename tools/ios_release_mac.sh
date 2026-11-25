#!/bin/bash
# Builds a signed App Store archive of Metro Tycoon: Türkiye and uploads it to
# App Store Connect (it then appears in TestFlight and can be submitted for review).
#
#   ./tools/ios_release_mac.sh <APPLE_TEAM_ID> [build_number]
#
# Signing: automatic. Either be signed in to Xcode with your Apple ID
# (Xcode → Settings → Accounts), or export an App Store Connect API key:
#   export ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-... ASC_KEY_PATH=/path/AuthKey_XXXX.p8
# The app record (bundle id below) must already exist in App Store Connect.
set -euo pipefail

TEAM_ID="${1:?Usage: $0 <APPLE_TEAM_ID> [build_number]}"
BUILD="${2:-$(date +%Y%m%d%H%M)}"
BUNDLE_ID="${BUNDLE_ID:-com.efeardaaric.metrotycoon}"
GODOT_VERSION="4.3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="$HOME/.cache/metrotycoon"
GODOT="$CACHE/Godot.app/Contents/MacOS/Godot"
TPL_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
OUT="$ROOT/build/ios_release"

mkdir -p "$CACHE"
rm -rf "$OUT" && mkdir -p "$OUT"
# Keep Godot from importing/exporting build output (old Xcode projects, PNGs in DerivedData).
touch "$ROOT/build/.gdignore"

if [ ! -x "$GODOT" ]; then
  echo "==> Downloading Godot $GODOT_VERSION"
  curl -L -o "$CACHE/godot.zip" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip"
  (cd "$CACHE" && unzip -q -o godot.zip)
fi
if [ ! -f "$TPL_DIR/ios.zip" ]; then
  echo "==> Downloading export templates (~1 GB)"
  curl -L -o "$CACHE/tpl.tpz" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
  rm -rf "$CACHE/tpl" && mkdir -p "$CACHE/tpl" "$TPL_DIR"
  (cd "$CACHE/tpl" && unzip -q "$CACHE/tpl.tpz")
  cp -R "$CACHE/tpl/templates/"* "$TPL_DIR/"
fi

cd "$ROOT"
cp export_presets.cfg "$CACHE/export_presets.backup.cfg"
trap 'cp "$CACHE/export_presets.backup.cfg" "$ROOT/export_presets.cfg"' EXIT
sed -i '' "s|application/app_store_team_id=\".*\"|application/app_store_team_id=\"$TEAM_ID\"|" export_presets.cfg
sed -i '' "s|application/bundle_identifier=\".*\"|application/bundle_identifier=\"$BUNDLE_ID\"|" export_presets.cfg
sed -i '' "s|application/export_project_only=false|application/export_project_only=true|" export_presets.cfg
sed -i '' "s|^application/version=\".*\"|application/version=\"$BUILD\"|" export_presets.cfg

echo "==> Importing project"
"$GODOT" --headless --path . --import || true
echo "==> Exporting Xcode project (release, build $BUILD)"
"$GODOT" --headless --path . --export-release "iOS" "$OUT/MetroTycoon.ipa"
PROJ="$(ls -d "$OUT"/*.xcodeproj | head -1)"
SCHEME="$(basename "$PROJ" .xcodeproj)"
# Godot hard-codes "iPhone Distribution"/"iPhone Developer" identities, which conflict with
# automatic signing. Use the automatic "Apple Development" identity for the archive.
sed -i '' -e 's/"iPhone Distribution"/"Apple Development"/g' -e 's/"iPhone Developer"/"Apple Development"/g' \
  "$PROJ/project.pbxproj"

AUTH=()
if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ]; then
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

echo "==> Archiving"
xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$OUT/MetroTycoon.xcarchive" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  DEVELOPMENT_TEAM="$TEAM_ID" PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" CODE_SIGN_STYLE=Automatic \
  archive
# The archive is development-signed; -exportArchive below re-signs it for App Store distribution.

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>${DESTINATION:-upload}</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

echo "==> Exporting & uploading to App Store Connect"
xcodebuild -exportArchive -archivePath "$OUT/MetroTycoon.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"}

echo "==> Done. Build $BUILD is processing in App Store Connect (TestFlight tab, ~10-30 min)."
echo "    Set DESTINATION=export to only produce an .ipa in $OUT/export without uploading."
