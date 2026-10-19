#!/bin/bash
# Instala o actualiza Mirro desde GitHub Releases.
#
#   curl -fsSL https://raw.githubusercontent.com/carlosmedina06/mirro/main/install.sh | bash
#
# Variables opcionales:
#   MIRRO_VERSION=1.0.0      instala una versión concreta (por defecto, la última)
#   MIRRO_INSTALL_DIR=...    carpeta de destino (por defecto /Applications)
#   MIRRO_NO_OPEN=1          no abrir la app al terminar
#
# Desinstalar:
#   curl -fsSL https://raw.githubusercontent.com/carlosmedina06/mirro/main/install.sh | bash -s -- --uninstall

set -euo pipefail

REPO="carlosmedina06/mirro"
APP_NAME="Mirro.app"
BUNDLE_ID="carlosmedina06.mirro"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

quit_app() {
    if pgrep -x Mirro >/dev/null; then
        info "Cerrando Mirro…"
        osascript -e "quit app id \"$BUNDLE_ID\"" 2>/dev/null || pkill -x Mirro || true
        sleep 1
    fi
}

install_dir() {
    if [[ -n "${MIRRO_INSTALL_DIR:-}" ]]; then
        echo "$MIRRO_INSTALL_DIR"
    elif [[ -w /Applications ]]; then
        echo /Applications
    else
        mkdir -p "$HOME/Applications"
        echo "$HOME/Applications"
    fi
}

uninstall() {
    bold "Desinstalando Mirro"
    quit_app
    local removed=0
    for dir in /Applications "$HOME/Applications"; do
        if [[ -d "$dir/$APP_NAME" ]]; then
            rm -rf "${dir:?}/$APP_NAME"
            info "Eliminado $dir/$APP_NAME"
            removed=1
        fi
    done
    defaults delete "$BUNDLE_ID" 2>/dev/null || true
    [[ $removed == 1 ]] && bold "✓ Mirro desinstalada" || info "Mirro no estaba instalada"
}

main() {
    [[ "${1:-}" == "--uninstall" ]] && { uninstall; return; }

    [[ "$(uname -s)" == "Darwin" ]] || fail "Mirro solo funciona en macOS"
    local macos_major
    macos_major=$(sw_vers -productVersion | cut -d. -f1)
    (( macos_major >= 13 )) || fail "Mirro requiere macOS 13 Ventura o posterior"

    bold "Instalando Mirro"

    local version="${MIRRO_VERSION:-}"
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
            | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1) || true
        [[ -n "$version" ]] || fail "No se pudo obtener la última versión desde GitHub"
    fi
    info "Versión $version"

    tmp=$(mktemp -d)
    trap 'rm -rf "${tmp:-}"' EXIT

    local base="https://github.com/$REPO/releases/download/v$version"
    local zip="Mirro-$version.zip"
    info "Descargando ${zip}…"
    curl -fsSL -o "$tmp/$zip" "$base/$zip" || fail "No se pudo descargar $base/$zip"
    curl -fsSL -o "$tmp/$zip.sha256" "$base/$zip.sha256" || fail "No se pudo descargar el checksum"

    info "Verificando checksum…"
    (cd "$tmp" && shasum -a 256 -c --quiet "$zip.sha256") || fail "El checksum no coincide; descarga corrupta"

    ditto -x -k "$tmp/$zip" "$tmp/unzipped"
    [[ -d "$tmp/unzipped/$APP_NAME" ]] || fail "El zip no contiene $APP_NAME"

    quit_app
    local dest
    dest=$(install_dir)
    rm -rf "${dest:?}/$APP_NAME"
    ditto "$tmp/unzipped/$APP_NAME" "$dest/$APP_NAME"
    # curl no marca los archivos como descargados de internet, pero por si acaso
    xattr -dr com.apple.quarantine "$dest/$APP_NAME" 2>/dev/null || true

    bold "✓ Mirro $version instalada en $dest/$APP_NAME"

    if [[ -z "${MIRRO_NO_OPEN:-}" ]]; then
        open "$dest/$APP_NAME"
    fi
}

# Todo dentro de main: si la descarga del script se corta a medias, no se ejecuta nada.
main "$@"
