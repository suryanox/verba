#!/bin/zsh
# Generates Config/AppIcon.icns (and a 1024px preview) from scripts/make-icon.swift.
# Run it again any time you tweak the artwork:  make icon
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
work_dir="$(mktemp -d)"
iconset="$work_dir/AppIcon.iconset"

swift "$project_root/scripts/make-icon.swift" "$iconset"
iconutil --convert icns "$iconset" --output "$project_root/Config/AppIcon.icns"
cp "$iconset/icon_512x512@2x.png" "$project_root/Config/AppIcon.png"
rm -rf "$work_dir"

echo "Created Config/AppIcon.icns"
echo "Preview: Config/AppIcon.png"
