# Distribución iOS Ad Hoc — Walvy

Cómo instalar builds de iOS en dispositivos de prueba, sin pasar por TestFlight ni App Store. Complementa [`testing.md`](testing.md) (que cubre tests automatizados, no distribución manual).

## Requisito único: estar logueado en EAS

Quien corra los comandos necesita `eas login` con acceso al proyecto `@migherize/walvy`. Esto se hace una sola vez por máquina.

## Paso 1 — Registrar un dispositivo nuevo (una sola vez por persona)

Solo hace falta la primera vez que una persona va a probar la app. Si ya registró su iPhone antes, **se salta este paso** para siempre, incluso para builds futuras.

```bash
cd front-walvy/expo
eas device:create
```

Elige la opción **"Website"**. Esto genera un link/QR:

1. Esa persona abre el link (o escanea el QR) **desde la Cámara de su propio iPhone**.
2. Le va a aparecer una notificación → la toca → **"Download Profile"**.
3. Va a **Ajustes** → aparece "Perfil descargado" → lo toca → **Instalar** (arriba a la derecha).

Con esto su dispositivo queda registrado permanentemente para este proyecto.

## Paso 2 — Generar una build nueva (cada vez que hay cambios que probar)

```bash
eas build --platform ios --profile preview
```

Esto compila una nueva versión incluyendo **automáticamente** a todos los dispositivos ya registrados (no hay que volver a registrar a nadie que ya esté en la lista). Tarda entre 10 y 20 minutos.

Si vas a sumar varias personas nuevas, conviene que todas registren su dispositivo primero (paso 1) y recién ahí corras una sola build — no hace falta una build por cada persona nueva.

## Paso 3 — Compartir la build

Al terminar, EAS te da una URL del estilo:
```
https://expo.dev/accounts/migherize/projects/walvy/builds/<id>
```

**Comparte esa URL** (no el archivo `.ipa`) con cada persona que quieras que pruebe. Cada una debe:
1. Abrir el link **en Safari desde su propio iPhone** (no desde el computador).
2. Tocar el botón **"Install"**.

> ⚠️ El archivo `.ipa` no se puede mandar por WhatsApp/mail para que alguien lo instale — iOS no soporta instalar así. Siempre tiene que ser el link de la build, abierto desde el iPhone de esa persona.

> ⚠️ Cada build nueva tiene una URL distinta. Si generas una build nueva, el link viejo queda desactualizado — comparte siempre el link de la última build.

## Límites

- Máximo ~100 dispositivos registrados por año en la cuenta de Apple Developer (de sobra para pruebas internas).
- Un dispositivo que ya probó una build vieja **no necesita hacer nada** para poder instalar una build nueva — solo abrir el nuevo link y tocar Install de nuevo.

## Contexto de la cuenta Apple / credenciales

La cuenta de Apple Developer (Team ID `SF25NVF54Y`) es de tipo **Individual**, propiedad de Rodrigo (`rodrigo@kabeli.cl`), quien es el Account Holder.

**Limitación importante**: en cuentas Individual, la gestión de Certificates/Identifiers/Profiles/Devices y la creación de APNs Keys está restringida al Account Holder — ningún otro rol (Admin, App Manager, Developer) delegado a otro miembro tiene acceso a esos recursos, ni siquiera vía API Key con rol Admin para ciertas acciones puntuales (confirmado con Xcode mostrando ❌ en "Certificates, Identifiers & Profiles" para un miembro con rol Admin). Si algún día hay que rehacer credenciales desde cero y algo falla con "no team associated with your Apple account" o similar, la solución es que **Rodrigo se autentique directamente** (Apple ID + clave + 2FA) en el paso que lo pida, no intentarlo con otra cuenta.

Credenciales ya configuradas para este proyecto (los archivos `.p8` viven fuera de todo repo, nunca se suben a git):

| Uso | Key ID | Issuer ID |
|---|---|---|
| ASC API Key (autenticación de `eas-cli` con Apple) | `N9CSRSNWDJ` | `137191f9-8324-493d-b3da-96e4496767b2` |
| APNs Key (push notifications) | `H334MGQ6T6` | — (las APNs Key no tienen Issuer ID) |

Si `eas build`/`eas credentials` piden estos datos interactivamente, son estos. Si en cambio piden login de Apple ID, usar el de Rodrigo si la acción requiere gestionar Certificates/Identifiers/Profiles/Devices/Push Keys.
