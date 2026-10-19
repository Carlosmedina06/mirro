---
title: Solución de problemas
---

## El teléfono no aparece

- Comprueba que la [depuración USB](./preparar-telefono) esté activada.
- Prueba otro cable: muchos cables solo cargan y no transmiten datos.
- Conéctalo directamente a la Mac, sin hubs.
- Desbloquea el teléfono: algunos no muestran el aviso de autorización con la pantalla bloqueada.
- En el teléfono, en la notificación de USB, elige **Transferencia de archivos**.

## Aparece «Acepta la depuración en el teléfono»

El teléfono está conectado, pero no ha autorizado a esta Mac. Desbloquéalo y acepta el aviso **¿Permitir depuración USB?**

Si el aviso no aparece, ve a **Opciones de desarrollador**, pulsa **Revocar autorizaciones de depuración USB**, desconecta y vuelve a conectar el cable.

## macOS dice que no puede verificar Mirro

Pasa si la descargaste desde el navegador. Ve a **Ajustes del Sistema › Privacidad y seguridad** y pulsa **Abrir igualmente**, o ejecuta:

```bash
xattr -dr com.apple.quarantine /Applications/Mirro.app
```

Más detalles en [Instalación](./instalacion#descarga-directa).

## Uso Android Studio y algo se desconecta

Mirro usa el `adb` que ya tengas instalado (Android Studio, Homebrew) para no pelear con él. Si aun así ves desconexiones, cierra Mirro, ejecuta `adb kill-server` y vuelve a abrirla.

## scrcpy termina con un error

Mirro muestra el error que devolvió scrcpy. Los más comunes:

- **Error de codificación de video:** prueba a bajar la **Resolución máxima** en las [opciones](./opciones).
- **Dispositivo desconectado:** revisa el cable o la conexión WiFi.

## No puedo usar el teclado ni el ratón (Xiaomi)

Activa **Depuración USB (ajustes de seguridad)** en las Opciones de desarrollador. Requiere tener una cuenta de Xiaomi iniciada en el teléfono.

## No se oye el audio

El audio requiere **Android 11** o posterior. Revisa también que no tengas activada la opción **Sin audio**.

## ¿Sigue sin funcionar?

[Abre un issue en GitHub](https://github.com/carlosmedina06/mirro/issues) con tu versión de macOS, el modelo del teléfono y el mensaje de error.
