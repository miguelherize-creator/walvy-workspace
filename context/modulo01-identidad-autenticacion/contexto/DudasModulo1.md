# M1 — Duda: tiempo de expiración del código de verificación

Contexto para el PM sobre una duda que surgió auditando la pantalla `/verify-code`
(paso posterior a `/register` en el flujo de registro).

## La pregunta

¿Los 15 minutos de expiración del código son mucho tiempo? ¿Convendría mostrar
5 minutos en el frontend en su lugar? ¿Qué pasa si el usuario ingresa el código
después de esos 5 minutos?

## Dónde vive cada cosa hoy

Son dos timers completamente independientes, en capas distintas:

| Timer | Dónde vive | Valor actual | Qué hace |
|---|---|---|---|
| Expiración real del código | Backend — `EMAIL_VERIFICATION_EXPIRES_MINUTES` (`email-verification.service.ts`) | 15 min | Determina hasta cuándo el código es válido. Se guarda `expiresAt` en BD y se valida server-side al momento de verificar. |
| Cooldown de "Reenviar código" | Frontend — `RESEND_COOLDOWN_SECONDS` (`useVerifyCodeForm.ts`) | Antes 30s → **subido a 5 min** | Solo controla cuándo se reactiva el botón "Reenviar código" en la UI (anti-spam). No tiene relación con la expiración real. |

Lo mismo aplica para reset de contraseña (`PASSWORD_RESET_EXPIRES_MINUTES`, también 15 min).

## Por qué NO conviene mostrar 5 min como "tiempo de expiración" en el frontend

Si el frontend mostrara un contador de 5 min como si fuera la expiración real,
mientras el backend sigue aceptando el código hasta el minuto 15, pasaría esto:

- Al llegar al minuto 5, la UI diría "código expirado" — pero el código **seguiría
  siendo válido** para el backend 10 minutos más.
- El usuario sería empujado a pedir un código nuevo sin necesidad, generando
  fricción falsa.

El único que sabe si el código sigue vivo es el backend. Mantener dos relojes
independientes (uno inventado en el front, otro real en el back) es una fuente
clásica de bugs de este tipo.

## Qué es estándar en pantallas de verificación (registro / 2FA por email)

- Rango típico de expiración real de un código por email: **5–15 min**. 15 min
  está en el extremo generoso pero es razonable (a diferencia de SMS, donde 5 min
  es más común porque se espera revisión inmediata).
- Sí es estándar mostrar un **cooldown corto para reenvío** (30s–1min típicamente,
  a veces más) — que es justamente lo que ya existía en esta pantalla.
- No es estándar mostrar un **countdown en vivo de la expiración real** del código
  (tipo "expira en 14:32"). En vez de eso, algunos productos usan un texto
  estático informativo ("tu código es válido por 15 minutos") que no cuenta
  hacia atrás y no puede desincronizarse del backend.

## Decisión tomada (2026-07-12)

- Se deja la expiración real en 15 min (sin cambios en backend).
- No se agrega countdown ni texto informativo de expiración en la UI por ahora.
- Se sube el cooldown de reenvío de 30s a **5 min** (`useVerifyCodeForm.ts`,
  `RESEND_COOLDOWN_SECONDS`).

## Abierto para decidir

- ¿Agregamos un texto estático (sin countdown) tipo "Tu código es válido por
  15 minutos" para que el usuario tenga la expectativa correcta, sin duplicar
  lógica de expiración en el frontend?

---

# M1 — Duda: chips "Face ID" / "Huella dactilar" en biometric-setup

Contexto: auditando `/biometric-setup` (pantalla posterior a verify-code en el
flujo de registro), se preguntó si los chips "Face ID" y "Huella dactilar" que
aparecen bajo el botón "Activar acceso rápido" son funcionales o solo texto.

## Qué son hoy

Son `<View>` planos sin `onPress` ni ningún handler — puramente decorativos.
Además, **se muestran siempre los dos, sin importar qué soporta el dispositivo**:
un iPhone con solo Face ID (sin Touch ID) igual muestra el chip "Huella dactilar".
El dato real del dispositivo (`biometricType`, calculado en
`services/biometrics.ts` vía `getBiometricType()`) se usa solo para decidir qué
`method` mandar al backend al activar — nunca para decidir qué chip pintar.

## Por qué no conviene hacerlos botones seleccionables

`expo-local-authentication` (`LocalAuthentication.authenticateAsync()`) no
permite pedir un método específico — dispara el prompt biométrico nativo del
OS tal como esté configurado en el dispositivo, sin forma de forzar "solo Face
ID" o "solo huella", ni de saber cuál usó el usuario si tiene ambos habilitados
(comentario existente en `services/biometrics.ts`: "en Samsung/Pixel con huella
+ rostro, no sabemos qué tab eligió el usuario — limitación de
expo-local-authentication"). La selección real la controla el sistema
operativo, no la app — convertir los chips en botones no le daría al usuario
ningún control adicional real.

## Recomendación

No hacerlos interactivos (no hay nada útil que "activar" por separado), pero
sí filtrar cuál chip se muestra según el `biometricType` real detectado en el
dispositivo, en vez de mostrar ambos siempre. Un dispositivo real nunca
combina ambos sensores como opciones activas simultáneas para la app, así que
mostrar los dos como si fueran opciones disponibles es información incorrecta,
no solo un detalle visual.

## Abierto para decidir

- ¿Se prioriza este fix (mostrar solo el chip correspondiente) para este sprint,
  o se deja como deuda técnica menor dado que no bloquea el flujo?

---

# M1 — Decisión: mínimo de caracteres del alias en choose-alias

Contexto: auditando `/choose-alias` (pantalla de "¿Cómo quieres que te
llamemos?" tras biometric-setup), surgió la duda de por qué el alias exigía un
mínimo de 3 caracteres.

## Lo que se encontró

La regla estaba duplicada en frontend (`useChooseAliasForm.ts`) y backend
(`UpdateProfileDto`, `@MinLength(3, ...)`), con el mismo mensaje de error en
ambos lados. Investigando el motivo, se encontró que el mínimo de 3 parece
haber sido pensado para un futuro login-por-alias (el mismo mínimo que usa el
clasificador de identificador en `registerIdentifier.ts`), **pero esa
funcionalidad no está conectada en el backend hoy**: `LoginDto` solo acepta
`email`, y `findByUsername()` en `users.service.ts` no lo llama nadie.

## Decisión tomada (2026-07-12)

El PM confirmó que el alias **no se va a usar para login** — es puramente un
dato de personalización ("cómo te saludamos"). Se baja el mínimo a 1 carácter
en ambas capas:

- Frontend (`useChooseAliasForm.ts`): se elimina el chequeo de longitud mínima.
- Backend (`update-profile.dto.ts`): `@MinLength(3, ...)` → `@MinLength(1, {
  message: 'El alias debe tener al menos 1 carácter' })`, mismo patrón que ya
  usan `firstName`/`lastName` en el mismo DTO.

Se mantiene el máximo de 50 caracteres y la regex de caracteres permitidos
(letras, números, punto, guion, guion bajo) — solo se quitó el piso.

## Nota relacionada, no resuelta en esta pasada

Sigue existiendo la inconsistencia entre `registerIdentifier.ts` (frontend,
piensa el alias como posible identificador de login) y el backend (que no
soporta login por alias ni tiene constraint de unicidad en `username`). Con
la decisión de hoy, esa brecha deja de importar para el flujo de registro,
pero si en algún momento se retoma la idea de login-por-alias, hay que revisar
esa parte por separado.
