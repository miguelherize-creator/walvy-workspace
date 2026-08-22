# 🔍 UI Visual QA — Modal de soporte de auth (AuthSupportModal)

**Figma principal:** `8040:9360` (`modal_walvy-B_support` — asset nuevo del mascot)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-08-18
**Auditor:** UI Visual QA Reviewer
**Alcance:** solo la pieza del mascot. El resto del modal (título, cuerpo, correo, botón) no se auditó en esta pasada.
**Consumidores:** `LoginScreen` (cuenta restringida, M1-BC-005) y `ForgotPasswordScreen` (M1-V19)

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**58 / 100** → **97 / 100** después del fix aplicado en esta misma sesión

### Estado General

❌ **RECHAZADO** en la primera pasada — el contenedor circular recortaba el 4.9% del contenido opaco del asset, justo el teléfono que el diseño nuevo agrega.
✅ **APROBADO** tras el fix.

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | **El teléfono queda cortado a ras.** El asset nuevo trae la elipse crema horneada y el teléfono se sale de ella por la izquierda; el contenedor `mascotCircle` (160×160, `borderRadius: 80`, `overflow: "hidden"`) lo recortaba. Medido: 4096 de 83388 px opacos (4.9%), filas y=121..285 del asset — mano y borde del teléfono | **Alta** |
| 2 | **Doble fondo con distinto crema.** `mascotCircle` pintaba `#F2EFE9` debajo de la elipse ya horneada del asset, que es `#F8F4ED` | Baja |
| 3 | **`resizeMode: "cover"` sobre un asset ya compuesto.** Con 325×320 en caja 160×160 escalaba a 162.5×160 y recortaba 1.25px por lado en X, además del clip circular | Media |
| 4 | **Geometría del nodo no respetada.** Figma declara 163.8×161.5 (elipse 160×160 con offset x 3.8 para dejar salir el teléfono); la implementación asumía 160×160 exactos | Media |

---

### Recomendaciones

#### Prioridad Alta

- Quitar el contenedor circular: el asset ya es la composición completa (elipse + mascot con desborde). Renderizar un solo `<Image>` de 164×162 con `resizeMode="contain"`. **Aplicado.**

#### Prioridad Media

- No reintroducir un `backgroundColor` en la caja del mascot: el crema es parte del asset, y hardcodearlo rompe dark mode (B03 de `visual-design-rules.md`). **Aplicado.**

#### Prioridad Baja

- El asset pesa 106,9 KB en webp con alpha para 325×320. Sirve, pero si el Designer republica, pedir ~2× del tamaño de uso (328×324) y no más.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación (antes) | Estado | Severidad |
|---|---|---|---|---|
| Caja del mascot | `163.798 × 161.5` | `160 × 160` con clip circular | Diferencia Crítica | Alta |
| Elipse de fondo | `160 × 160`, offset x `3.8` | Contenedor sin offset — el desborde izquierdo cae fuera del clip | Diferencia Crítica | Alta |
| Desborde inferior | `1.5px` bajo la elipse | Recortado | Diferencia Menor | Baja |
| Caja del mascot (después) | `163.798 × 161.5` | `164 × 162`, `contain` → render `164 × 161.5` | OK (letterbox 0.26px) | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación (antes) | Estado | Severidad |
|---|---|---|---|---|
| Fondo de la elipse | `#F8F4ED` (horneado en el asset) | `#F2EFE9` pintado por el contenedor | Diferencia Menor | Baja |
| Fondo de la elipse (después) | `#F8F4ED` | Sin `backgroundColor` — lo aporta el asset | OK | — |

### Fase 4 — Componentes

| Elemento | Figma | Implementación (antes) | Estado | Severidad |
|---|---|---|---|---|
| Composición del asset | Un solo export ya compuesto | Recompuesto en runtime (círculo + `cover`) | Diferencia Media | Media |

### Fase 7 — Accesibilidad

Sin hallazgos: la pieza es decorativa y no aporta ni bloquea texto.

---

## 🏁 Veredicto

El asset nuevo cambia de contrato respecto al anterior y ahí estaba el problema. El viejo (`nueva_recuperar_acceso_correo_login.png`, 164×153, fondo transparente) necesitaba que el código le pusiera el círculo crema debajo. El nuevo (`modal_walvy-B_support.webp`, 325×320) ya trae la elipse `#F8F4ED` horneada y, encima, contenido que sale de ella a propósito. Al cambiar solo la URL en `media.ts` y dejar el `mascotCircle` de antes, el clip circular cortaba plano el teléfono — es decir, se perdía justo lo que el rediseño aporta.

El fix es una simplificación: un `<Image>` de 164×162 con `contain`, sin contenedor ni fondo. Verificado contra el render de Figma reproduciendo el pipeline de `resizeMode` fuera de la app; `typecheck` y `lint` limpios y las 192 pruebas en verde.

Queda pendiente auditar el resto del modal (tipografía del título, cuerpo, enlace de correo y botón) contra su nodo de Figma, que no es este.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-08-18 (#1) | 58/100 | El contenedor circular recortaba el teléfono del asset nuevo (4.9% del contenido opaco) |
| 2026-08-18 (#2) | 97/100 | Fix aplicado: `<Image>` 164×162 `contain`, sin `mascotCircle` ni `backgroundColor` |
