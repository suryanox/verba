#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-debug}"
build_root="$project_root/.build"
binary="$build_root/arm64-apple-macosx/$configuration/Verba"
app="$build_root/Verba.app"

cd "$project_root"
swift build -c "$configuration"

icon="$project_root/Config/AppIcon.icns"
if [[ ! -f "$icon" || "$project_root/scripts/make-icon.swift" -nt "$icon" ]]; then
    zsh "$project_root/scripts/make-icon.sh"
fi

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary" "$app/Contents/MacOS/Verba"
cp "$project_root/Config/Info.plist" "$app/Contents/Info.plist"
cp "$project_root/Config/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --deep --sign - --timestamp=none "$app" >/dev/null

echo "Built $app"
echo "Run with: open $app"
