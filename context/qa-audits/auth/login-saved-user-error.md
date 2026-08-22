# 🔍 UI Visual QA — `/login` savedUser estado ERROR (LoginScreen — modo `savedUserPassword` + 401)

**Figma principal:** `3677:2914` (componente Input en estado error)
**Figma estado default:** `3470:7098`
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-08-18 (#3 — reemplaza el informe del 2026-05-31, que quedó desactualizado)
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**74 / 100** → **96 / 100** después de los fixes aplicados en esta sesión

### Estado General

⚠️ **Aprobado con observaciones** tras el fix. Queda un punto abierto de severidad Baja (peso del label) y una divergencia consciente (sombra rosa).

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | **Mensaje sin sentido en savedUser mode.** El 401 mostraba "Correo o contraseña incorrectos" en una pantalla donde el campo de correo no existe. Figma pide "Contraseña incorrecta. Revísala antes de continuar." | **Alta** |
| 2 | **El texto de error no rendía SemiBold.** `errorText` declaraba `fontWeight: "600"` sin `fontFamily`: Manrope se registra con una cara por peso, así que el texto caía al font del sistema | Media |
| 3 | **Texto de error mal posicionado.** `marginTop: 4` y `marginLeft: 4` contra el `gap: 8` y `x: 0` del nodo | Media |
| 4 | Label "Contraseña": Figma lo declara Regular, la implementación usa `fontFamily.bold` + `fontWeight: 600` | Baja |

---

### Recomendaciones

#### Prioridad Alta

- Diferenciar el 401 por modo en `useLoginForm`: genérico de M1-V03 en `firstTime`, "Contraseña incorrecta. Revísala antes de continuar." en savedUser. **Aplicado.**

#### Prioridad Media

- Dar `fontFamily.semiBold` y `lineHeight: 16` al texto de error, y alinearlo con el borde del input (`marginTop: 8`, `marginLeft: 0`). Aplicado bajo `figmaLogin` para no tocar las pantallas que no usan este componente de Figma. **Aplicado.**

#### Prioridad Baja — pendiente

- Peso del label. `labelFigma` lo comparten todos los inputs de auth, así que bajarlo a Regular es un cambio transversal que hay que auditar contra los nodos default de cada pantalla antes de tocarlo — no entra en un fix de mensaje. **Pendiente.**

---

## ✅ Lo que ya estaba resuelto (contra el informe #1)

El informe del 2026-05-31 daba como bug raíz que `useLoginForm` validaba el campo email en savedUser mode y por eso salía "Ingresa tu correo electrónico". **Eso ya está corregido:** el hook resuelve `effectiveUserEmail` desde `user.email` o `savedEmail` del SecureStore, y `LoginScreen` ya cablea `error={passwordError}` en el input de Contraseña y suprime el `AuthMessageBox` cuando hay `passwordError`. También estaba mal la copy citada: el nodo dice "Revísala", no "Revísalas".

Lo que quedaba vivo era solo el texto del 401 y la tipografía del mensaje.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación (antes) | Estado | Severidad |
|---|---|---|---|---|
| Posición del error | bajo el input, dentro del componente | bajo el input | OK | — |
| `AuthMessageBox` externo | no existe | suprimido cuando hay `passwordError` | OK | — |
| Input → mensaje | `gap: 8` | `marginTop: 4` | Diferencia Menor | Media |
| Sangría del mensaje | `x: 0`, alineado al input | `marginLeft: 4` | Diferencia Menor | Media |
| Alto del input | `52` | `52` | OK | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación (antes) | Estado | Severidad |
|---|---|---|---|---|
| Texto del error | "Contraseña incorrecta. Revísala antes de continuar." | "Correo o contraseña incorrectos" | Diferencia Crítica | Alta |
| Familia del error | SemiBold | sin `fontFamily` → font del sistema | Diferencia Media | Media |
| Tamaño / lineHeight del error | `12 / 16` | `12`, sin `lineHeight` | Diferencia Menor | Media |
| Tracking del error | `0.6` | `0.6` | OK | — |
| Label "Contraseña" | Regular 12, tracking 0.6 | bold + `fontWeight: 600` | Diferencia Menor | Baja |
| Contenido del input (filled) | SemiBold 16 | `inputFigmaFilled` = SemiBold 16 | OK | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Borde en error | `#E9B9BF` | `#E9B9BF` (`errorBorderColor` con `figmaLogin`) | OK | — |
| Color del texto de error | `#BD4756` | `#BD4756` | OK | — |
| Fondo del input | `#FFFCFA` | `#FFFCFA` | OK | — |
| Color del label | `#3F484A` | `theme.inputLabelText` = `#3F484A` | OK | — |
| Sombra en error | `2px 2px 16px #FBD8DC` | sin sombra | Divergencia consciente | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Input en error | borde rosa + texto de ayuda debajo | `AppInput` con `error` | OK | — |
| Ojo del password | `18 × 16` | lucide `Eye`/`EyeOff` a `18` | OK aproximado | Baja |

### Fase 7 — Accesibilidad

| Aspecto | Estado |
|---|---|
| Contraste del error (`#BD4756` sobre `#FFFCFA`) | OK — 5.1:1 |
| Asociación error ↔ campo | OK — el mensaje queda pegado al input, y ahora nombra el campo que el usuario puede corregir |

---

## 🔒 Nota de M1-V03

El mensaje genérico de login existe para no delatar si un correo está registrado. Diferenciarlo en savedUser mode no lo debilita: la cuenta ya está guardada en el dispositivo y la pantalla ni muestra el campo de correo, así que "Contraseña incorrecta" no agrega información que un tercero no tuviera ya con el teléfono en la mano. Los dos casos de `firstTime` siguen cubiertos por el test parametrizado que verifica que la UI no repite el texto del backend.

---

## 🏁 Veredicto

El bug era de copy y de contexto, no de cableado: el estado de error ya se pintaba bien en el input, pero el 401 usaba un solo mensaje para los dos modos y en savedUser hablaba de un campo que no está en pantalla. La diferenciación va en `useLoginForm`, donde ya se distingue 401 de 403, así que no hizo falta tocar `LoginScreen`.

De paso salió un defecto tipográfico real que el informe anterior no había visto: el texto de error nunca rindió SemiBold porque `fontWeight` sin `fontFamily` no elige cara en Manrope. Corregido bajo `figmaLogin` para no arrastrar a las pantallas que no usan este componente.

Queda abierto el peso del label, que es transversal a todos los inputs de auth, y la sombra rosa como divergencia consciente ya justificada en el código.

Con el label a Regular el score subiría a ~99/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-30 (#1) | 52/100 | 5 issues críticos: validaba email en savedUser mode y mostraba el error en un box externo |
| 2026-05-31 (#2) | — | Fixes de cableado: `effectiveUserEmail`, error inline en el input, `AuthMessageBox` suprimido |
| 2026-08-18 (#3) | 74/100 → 96/100 | El 401 no distinguía modo; el texto de error no rendía SemiBold ni respetaba el gap del nodo |
