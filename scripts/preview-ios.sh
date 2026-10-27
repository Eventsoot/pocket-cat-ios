#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
runtime=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; r=[x["identifier"] for x in json.load(sys.stdin)["runtimes"] if x.get("isAvailable") and x["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS")]; print(r[-1] if r else "")')
test -n "$runtime"
device=$(xcrun simctl create PocketCatPreview com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max "$runtime")
build_root=$(mktemp -d "${TMPDIR:-/tmp}/pocketcat-preview.XXXXXX")
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true; xcrun simctl delete "$device" >/dev/null 2>&1 || true; rm -rf -- "$build_root"' EXIT
xcrun simctl boot "$device"
xcrun simctl bootstatus "$device" -b
xcodebuild -project PocketCat.xcodeproj -scheme PocketCat -configuration Debug \
  -sdk iphonesimulator -destination "id=$device" -derivedDataPath "$build_root" \
  CODE_SIGNING_ALLOWED=NO build > output/simulator-build.log 2>&1
xcrun simctl status_bar "$device" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl install "$device" "$build_root/Build/Products/Debug-iphonesimulator/PocketCat.app"
for tab in 0 1 2; do
  xcrun simctl launch --terminate-running-process "$device" com.example.PocketCat "--preview-tab=$tab"
  sleep 10
  xcrun simctl io "$device" screenshot "output/iphone13-tab-${tab}.png"
done
xcrun simctl launch --terminate-running-process "$device" com.example.PocketCat --preview-tab=1 --preview-game
sleep 5
xcrun simctl io "$device" screenshot "output/iphone13-adventure.png"
echo 'Captured actual iPhone 13 Pro Max simulator screens.'
