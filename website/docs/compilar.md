---
title: Compilar desde el código
---

Solo necesitas las Command Line Tools de Xcode:

```bash
xcode-select --install
```

## Compilar

```bash
git clone https://github.com/carlosmedina06/mirro.git
cd mirro
make          # genera build/Mirro.app (universal: Apple Silicon + Intel)
make install  # además la copia a /Applications
```

La compilación descarga las builds oficiales de scrcpy para macOS, verifica su SHA-256 y las empaqueta dentro de la app.

## Comandos

| Comando | Qué hace |
| --- | --- |
| `make` | Compila `build/Mirro.app` |
| `make install` | Compila e instala en `/Applications` |
| `make release` | Genera `dist/Mirro-x.y.z.zip` y su `.sha256` para GitHub Releases |
| `make icon` | Regenera el icono desde `scripts/icon.swift` |
| `make clean` | Borra `build/` y `dist/` |

## Estructura

```
Sources/          Código de la app (Swift + SwiftUI)
  main.swift        Barra de estado y ventana
  Model.swift       Estado compartido y sesiones de scrcpy
  Views.swift       Interfaz
  ADB.swift         Dispositivos y llamadas a adb
  StatusIcon.swift  Icono de la barra de estado
Resources/        Icono de la app
scripts/          Compilar, publicar y regenerar el icono
install.sh        Instalador de una línea
website/          Esta web (Docusaurus)
```

## Publicar una versión

1. Cambia `VERSION` en `scripts/build.sh`.
2. Ejecuta `make release`.
3. Crea el tag y el release en GitHub, y adjunta `dist/Mirro-x.y.z.zip` y `dist/Mirro-x.y.z.zip.sha256`.

## La web

```bash
cd website
npm install
npm start     # servidor local en http://localhost:3000/mirro/
```

Se publica automáticamente en GitHub Pages al hacer push a `main`.
