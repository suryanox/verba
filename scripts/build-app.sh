#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-debug}"
build_root="$project_root/.build"
binary="$build_root/arm64-apple-macosx/$configuration/Verba"
app="$build_root/Verba.app"

cd "$project_root"
swift build -c "$configuration"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$binary" "$app/Contents/MacOS/Verba"
cp "$project_root/Config/Info.plist" "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --deep --sign - --timestamp=none "$app" >/dev/null

echo "Built $app"
echo "Run with: open $app"
