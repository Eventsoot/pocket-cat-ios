#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

flavor="${1:-basic}"
case "$flavor" in
  basic) spec=project-basic.yml ;;
  widgets) spec=project.yml ;;
  *) echo 'Expected basic or widgets.' >&2; exit 64 ;;
esac

if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This build requires macOS and Xcode. Run the GitHub Actions workflow.' >&2
  exit 1
fi

mkdir -p output
build_root="$(mktemp -d "${TMPDIR:-/tmp}/pocketcat-${flavor}.XXXXXX")"
trap 'rm -rf -- "$build_root"' EXIT

xcodegen generate --spec "$spec"
xcodebuild -version | tee "output/toolchain-${flavor}.txt"
xcodebuild \
  -project PocketCat.xcodeproj \
  -scheme PocketCat \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$build_root/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | tee "output/build-${flavor}.log"

app="$build_root/DerivedData/Build/Products/Release-iphoneos/PocketCat.app"
test -d "$app"
test -f "$app/PocketCat"
plutil -lint "$app/Info.plist"
if [[ "$flavor" == widgets ]]; then
  test -d "$app/PlugIns/PocketCatWidgets.appex"
else
  test ! -d "$app/PlugIns/PocketCatWidgets.appex"
fi
mkdir -p "$build_root/package/Payload"
ditto "$app" "$build_root/package/Payload/PocketCat.app"
destination="$PWD/output/PocketCat-${flavor}-unsigned.ipa"
(cd "$build_root/package" && /usr/bin/zip -qry "$destination" Payload)
unzip -t "$destination"
echo 'IPA compiled for a physical iPhone. It still requires on-device-account signing with a sideloading tool.'
