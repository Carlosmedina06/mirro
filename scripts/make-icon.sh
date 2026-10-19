#!/bin/zsh
# Regenera Resources/AppIcon.icns y docs/icon.png a partir de scripts/icon.swift.
# Uso: scripts/make-icon.sh  (o: make icon)
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

swift scripts/icon.swift "$TMP/icon-1024.png" >/dev/null
mkdir -p "$TMP/AppIcon.iconset" Resources docs
for s in 16 32 128 256 512; do
    sips -z $s $s "$TMP/icon-1024.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$TMP/icon-1024.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$TMP/AppIcon.iconset" -o Resources/AppIcon.icns
sips -z 256 256 "$TMP/icon-1024.png" --out docs/icon.png >/dev/null
echo "✓ Resources/AppIcon.icns"
echo "✓ docs/icon.png"
