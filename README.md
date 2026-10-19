<p align="center">
  <img src="docs/icon.png" width="128" alt="Mirro">
</p>

<h1 align="center">Mirro</h1>

<p align="center">
  Duplica y controla tus teléfonos Android desde la barra de estado de tu Mac.
</p>

<p align="center">
  <a href="https://carlosmedina06.github.io/mirro/"><b>Web y documentación</b></a>
</p>

---

Mirro es una app nativa de macOS que vive en la barra de estado y te permite ver y usar la pantalla de tus dispositivos Android con un clic. Por debajo usa [scrcpy](https://github.com/Genymobile/scrcpy), que ya viene incluido: no hay que instalar nada más.

## Funciones

- **Un clic para duplicar** cualquier teléfono conectado, desde la barra de estado o desde la ventana principal
- **Varios dispositivos a la vez**, con «Duplicar todos» y «Detener todos»
- **USB o WiFi**: pasa un teléfono USB a WiFi automáticamente o conéctate por IP
- **Información del dispositivo**: modelo, marca, versión de Android y batería
- **Onboarding** que te guía para activar la depuración USB
- **Opciones**: apagar la pantalla del teléfono, mantenerlo despierto, sin audio, ventana siempre encima, mostrar toques y resolución máxima
- **Abrir al iniciar sesión**

## Instalación

### Recomendado: Terminal

```sh
curl -fsSL https://raw.githubusercontent.com/carlosmedina06/mirro/main/install.sh | bash
```

Descarga la última versión desde [Releases](https://github.com/carlosmedina06/mirro/releases/latest), verifica su checksum, la instala en `/Applications` y la abre. Puedes [leer el script](install.sh) antes de ejecutarlo. Para actualizar, vuelve a ejecutar el mismo comando.

Para desinstalar:

```sh
curl -fsSL https://raw.githubusercontent.com/carlosmedina06/mirro/main/install.sh | bash -s -- --uninstall
```

### Descarga directa

Descarga `Mirro-x.y.z.zip` desde [Releases](https://github.com/carlosmedina06/mirro/releases/latest), descomprímelo y mueve **Mirro.app** a `/Applications`.

> **Si usaste la descarga directa:** Mirro todavía no está notarizada por Apple, así que la primera vez macOS la bloquea con el aviso *«Apple no pudo verificar…»*. Intenta abrirla, cierra el aviso y ve a **Ajustes del Sistema › Privacidad y seguridad › Abrir igualmente**. O ejecuta `xattr -dr com.apple.quarantine /Applications/Mirro.app`. Solo hace falta una vez. Con el instalador de Terminal no ocurre.

## Requisitos

- macOS 13 Ventura o posterior
- Mac con Apple Silicon o Intel
- Un teléfono Android con la **depuración USB** activada (Mirro te explica cómo)

Si ya tienes `adb` instalado (por ejemplo, con Android Studio), Mirro usa ese para no interferir con tus herramientas. Si no, usa el que trae incluido.

## Compilar desde el código

Solo necesitas las Command Line Tools de Xcode (`xcode-select --install`).

```sh
git clone https://github.com/carlosmedina06/mirro.git
cd mirro
make          # genera build/Mirro.app (universal: Apple Silicon + Intel)
make install  # además la copia a /Applications
```

La compilación descarga las builds oficiales de scrcpy para macOS y verifica su SHA-256 antes de empaquetarlas.

### Estructura

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
website/          Web y documentación (Docusaurus)
```

### Comandos

| Comando | Qué hace |
| --- | --- |
| `make` | Compila `build/Mirro.app` |
| `make install` | Compila e instala en `/Applications` |
| `make release` | Genera `dist/Mirro-x.y.z.zip` y su `.sha256` para GitHub Releases |
| `make icon` | Regenera el icono desde `scripts/icon.swift` |
| `make clean` | Borra `build/` y `dist/` |

La versión se define en `scripts/build.sh` (`VERSION`).

## Créditos

Mirro no sería posible sin [**scrcpy**](https://github.com/Genymobile/scrcpy) de Genymobile y Romain Vimont, que se distribuye dentro de la app sin modificaciones bajo la [licencia Apache 2.0](https://github.com/Genymobile/scrcpy/blob/master/LICENSE). También incluye `adb` de [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools).

Mirro no está afiliada a Genymobile ni a Google. Android es una marca de Google LLC.

## Licencia

[MIT](LICENSE) © Carlos Medina
