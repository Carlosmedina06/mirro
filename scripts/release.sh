#!/bin/zsh
# Genera el .zip y su checksum para GitHub Releases.
# Uso: scripts/release.sh  (o: make release)
set -euo pipefail
cd "$(dirname "$0")/.."

GITHUB_USER="carlosmedina06"

VERSION=$(grep '^VERSION=' scripts/build.sh | cut -d'"' -f2)
ZIP="dist/Mirro-$VERSION.zip"

scripts/build.sh
rm -rf dist && mkdir dist
ditto -c -k --sequesterRsrc --keepParent build/Mirro.app "$ZIP"
(cd dist && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256")

cat <<EOF

✓ $ZIP
✓ $ZIP.sha256

Siguientes pasos:
  1. git tag v$VERSION && git push origin v$VERSION
  2. Crea el release v$VERSION en https://github.com/$GITHUB_USER/mirro/releases/new
     y adjunta $ZIP y $ZIP.sha256
EOF
