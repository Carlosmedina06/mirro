#!/bin/zsh
# Compila Mirro.app. Uso: ./build.sh [--install]
set -euo pipefail
cd "$(dirname "$0")"

NAME="Mirro"
VERSION="1.0.0"
APP="build/$NAME.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Binario universal: Apple Silicon + Intel
for arch in arm64 x86_64; do
    swiftc -O -target $arch-apple-macos13 Sources/*.swift -o "build/$NAME-$arch"
done
lipo -create "build/$NAME-arm64" "build/$NAME-x86_64" -output "$APP/Contents/MacOS/$NAME"

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
typeset -A SCRCPY_SHA256=(
    aarch64 33611e51977a8289e2e124b220f727895181ef2eb9060e0987a4dc2db9cf0d6b
    x86_64  31a5467a9e907f162b093267cbbab1276b15c6e709c2ea8159566a8d165beb50
)
mkdir -p vendor "$APP/Contents/Resources/bin"
for arch in aarch64 x86_64; do
    tgz="vendor/scrcpy-macos-$arch-v$SCRCPY_VERSION.tar.gz"
    if [[ ! -f "$tgz" ]]; then
        curl -fsSL -o "$tgz.part" \
            "https://github.com/Genymobile/scrcpy/releases/download/v$SCRCPY_VERSION/scrcpy-macos-$arch-v$SCRCPY_VERSION.tar.gz"
        mv "$tgz.part" "$tgz"
    fi
    echo "${SCRCPY_SHA256[$arch]}  $tgz" | shasum -a 256 -c --quiet || { echo "✗ checksum de scrcpy ($arch) no coincide"; rm -f "$tgz"; exit 1; }
    mkdir -p "build/scrcpy-$arch"
    tar -xzf "$tgz" -C "build/scrcpy-$arch" --strip-components 1
done
# scrcpy viene por arquitectura; scrcpy-server y adb (ya universal) son idénticos en ambas
lipo -create build/scrcpy-aarch64/scrcpy build/scrcpy-x86_64/scrcpy -output "$APP/Contents/Resources/bin/scrcpy"
for f in scrcpy-server adb scrcpy.png disconnected.png LICENSE; do
    cp "build/scrcpy-aarch64/$f" "$APP/Contents/Resources/bin/"
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
