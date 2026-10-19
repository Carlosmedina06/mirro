#!/bin/zsh
# Genera el .zip para GitHub Releases y actualiza el cask del tap.
# Uso: ./release.sh
set -euo pipefail
cd "$(dirname "$0")"

GITHUB_USER="carlosmedina06"
TAP_DIR="../homebrew-tap"          # clon local de github.com/$GITHUB_USER/homebrew-tap

VERSION=$(grep '^VERSION=' build.sh | cut -d'"' -f2)
ZIP="dist/Mirro-$VERSION.zip"

./build.sh
rm -rf dist && mkdir dist
ditto -c -k --sequesterRsrc --keepParent build/Mirro.app "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

if [[ -f "$TAP_DIR/Casks/mirro.rb" ]]; then
    sed -i '' -E "s/^  version \".*\"/  version \"$VERSION\"/; s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$TAP_DIR/Casks/mirro.rb"
    echo "✓ Cask actualizado: $TAP_DIR/Casks/mirro.rb"
fi

cat <<EOF

✓ $ZIP
  sha256 $SHA

Siguientes pasos:
  1. git tag v$VERSION && git push origin v$VERSION
  2. Crea el release v$VERSION en https://github.com/$GITHUB_USER/mirro/releases/new
     y adjunta $ZIP
  3. En $TAP_DIR: git commit -am "mirro $VERSION" && git push
EOF
