#!/bin/zsh
# Compila Mirro.app. Uso: ./build.sh [--install]
set -euo pipefail
cd "$(dirname "$0")"

NAME="Mirro"
VERSION="1.0.0"
APP="build/$NAME.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target arm64-apple-macos13 Sources/*.swift -o "$APP/Contents/MacOS/$NAME"

# Icono: dibuja el PNG maestro y genera todos los tamaños del .icns
ICONSET="build/AppIcon.iconset"
mkdir -p "$ICONSET"
swift Tools/make-icon.swift build/icon-1024.png >/dev/null
for s in 16 32 128 256 512; do
    sips -z $s $s build/icon-1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) build/icon-1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# scrcpy oficial (Apache 2.0) empaquetado dentro de la app: no hay que instalar nada.
# Se descarga una vez a vendor/ y se verifica contra el SHA-256 publicado.
SCRCPY_VERSION="5.0.1"
SCRCPY_SHA256="33611e51977a8289e2e124b220f727895181ef2eb9060e0987a4dc2db9cf0d6b"
SCRCPY_TGZ="vendor/scrcpy-macos-aarch64-v$SCRCPY_VERSION.tar.gz"
if [[ ! -f "$SCRCPY_TGZ" ]]; then
    mkdir -p vendor
    curl -fsSL -o "$SCRCPY_TGZ.part" \
        "https://github.com/Genymobile/scrcpy/releases/download/v$SCRCPY_VERSION/scrcpy-macos-aarch64-v$SCRCPY_VERSION.tar.gz"
    mv "$SCRCPY_TGZ.part" "$SCRCPY_TGZ"
fi
echo "$SCRCPY_SHA256  $SCRCPY_TGZ" | shasum -a 256 -c --quiet || { echo "✗ checksum de scrcpy no coincide"; rm -f "$SCRCPY_TGZ"; exit 1; }
mkdir -p build/scrcpy "$APP/Contents/Resources/bin"
tar -xzf "$SCRCPY_TGZ" -C build/scrcpy --strip-components 1
for f in scrcpy scrcpy-server adb scrcpy.png disconnected.png LICENSE; do
    cp "build/scrcpy/$f" "$APP/Contents/Resources/bin/"
done
xattr -cr "$APP/Contents/Resources/bin"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$NAME</string>
    <key>CFBundleDisplayName</key><string>$NAME</string>
    <key>CFBundleIdentifier</key><string>carlosmedina06.mirro</string>
    <key>CFBundleExecutable</key><string>$NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "✓ $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf "/Applications/$NAME.app"
    cp -R "$APP" /Applications/
    echo "✓ Instalada en /Applications/$NAME.app"
fi
