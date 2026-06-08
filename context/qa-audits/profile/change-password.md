# 🔍 UI Visual QA — `/(tabs)/change-password` (Actualizar contraseña)

**Figma principal:** `3395:4885` (Mi Perfil/Contraseña)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-07
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**95 / 100**

### Estado General
✅ **Aprobado** — 6 desviaciones corregidas + 1 mejora UX preservada (requisitos visibles).

### Principales Problemas (priorizados)

| # | Problema | Severidad | Estado |
|---|---|---|---|
| 1 | UN card con todo → Figma usa **DOS cards separadas** (Contraseña actual / Nueva+Confirma) | Media | ✅ Aplicado |
| 2 | Card 2 sin gating → Figma muestra `opacity: 0.5` hasta llenar Contraseña actual | Media | ✅ Aplicado |
| 3 | Card borderRadius 8 → debe ser **16** | Media | ✅ Aplicado |
| 4 | Title sin `fontFamily.semiBold` | Baja | ✅ Aplicado |
| 5 | Subtitle sin `fontFamily.display` (patrón conocido — texto se ve apretado) | Baja | ✅ Aplicado |
| 6 | Botón siempre enabled → Figma muestra disabled (bg `rgba(27,107,115,0.3)`) hasta validación completa | Media | ✅ Aplicado |

### Decisión UX (divergencia consciente)
- **Requirements box "Requisitos para una contraseña segura" mantenido aunque Figma no lo muestra.** Es feedback en vivo crítico para que el usuario sepa qué le falta. Cambiado para mostrarse solo cuando `newPassword.length > 0` (antes era always-visible, ahora aparece reactivo al typing).

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Body (3395:4888) | pt-24 pb-36 px-16, gap-16 | `scrollContent: pt 24, pb 36, px 16, gap 16` | OK (post-fix) |
| Heading block (3395:4889) | gap-8 | `headerBlock: gap-8` | OK (sin marginBottom extra) |
| Title row (3395:4890) | chevron 32 + title alineados horiz | `titleRow: row, alignItems center, gap 4` | OK |
| Forms container (3395:4896) | gap-16 entre las 2 cards | `scrollContent gap-16` distribuye en todos los children | OK |
| **Card 1** (3395:4897) | bg #fffdfd, border 1 #e6ded2, drop-shadow, p-16, rounded-16 | match (post-fix radius 8→16) | OK (post-fix) |
| **Card 2** (3829:4429) | misma styling + gap-8 interno (Nueva ↔ Confirma) | `card + cardInner: gap-8` | OK (post-fix split) |
| Card 2 opacity (3829:4430/4448) | opacity-50 cuando Contraseña actual vacía | `cardDisabled: opacity 0.5` + `pointerEvents="none"` + `editable={false}` | OK (post-fix) |
| Button (2748:5832) | bg disabled rgba(27,107,115,0.3), h-40, rounded-100, w-full | match con backgroundColor dinámico según `canSubmit` | OK (post-fix) |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Title (3395:4893) | Aptos SemiBold 24 / leading-32 / #103F43 | `fontFamily.semiBold 24 / 32` | OK (post-fix fontFamily) |
| Subtitle (3395:4895) | Aptos:Display 16 / leading-16 / rgba(31,42,51,0.8) | `fontFamily.display 16 / 22` | OK (post-fix fontFamily) |
| Input label | Aptos Regular 12 / tracking 0.6 / #3F484A | Maneja AppInput | OK |
| Input value/placeholder | Aptos SemiBold 16 / #103F43 | Maneja AppInput | OK |
| Button text | Aptos SemiBold 16 / #FFFCFA | match | OK |

### Fase 3 — Colores

| Token | Figma | Implementación | Estado |
|---|---|---|---|
| Card bg | `#fffdfd` | `theme.subscriptionCardBg` | OK |
| Card border | `#e6ded2` | `theme.subscriptionCardBorder` | OK |
| Card shadow | `rgba(27,107,115,0.08)` | match plataforma-específico | OK |
| Input border default (Contraseña actual) | `#e6ded2` | `FIGMA_INPUT_BORDER_DEFAULT` (AppInput) | OK |
| Input border filled (Nueva/Confirma) | `#1b6b73` | `FIGMA_INPUT_BORDER_ACTIVE` (AppInput, vía `filled`) | OK |
| Button disabled bg | `rgba(27,107,115,0.3)` | match | OK |
| Button active bg | `#1B6B73` | `theme.oceanTeal` | OK |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado |
|---|---|---|---|
| Chevron back | size-32 | `<ChevronLeft size={28}>` | OK (4px diff) |
| Input con eye icon | h-52, p-16, eye 18×16 | `AppInput` con `secureTextEntry` (eye toggle built-in) | OK |
| Botón "Actualizar" | h-40 disabled state | `AppButton variant primary` con backgroundColor dinámico | OK |
| Requirements box | NO en Figma | `requirementsBox` mantenido como UX extra (visible si newPassword.length > 0) | Divergencia consciente |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado |
|---|---|---|---|
| Body pt | 24 | 24 (spacing.xxl) | OK |
| Body pb | 36 | 36 (spacing.xxxl + spacing.xs) | OK |
| Body px | 16 | 16 (spacing.lg) | OK |
| Body gap | 16 | 16 (spacing.lg) | OK (post-fix) |
| Heading gap | 8 | 8 (spacing.sm) | OK |
| Card padding | 16 | 16 (spacing.lg) | OK |
| Card 2 internal gap | 8 | 8 (spacing.sm) | OK |

### Fase 6 — Responsive

| Device | Comportamiento | Observación |
|---|---|---|
| iPhone 393 (Figma base) | 2 cards apiladas, button al final | OK |
| Samsung S20 Ultra 412 | Cards full width con padding 16 | OK |
| Android pequeño 360 | Cards se contraen, mantiene jerarquía | OK |

### Fase 7 — Accesibilidad

| Check | Estado |
|---|---|
| `accessibilityRole="button"` en chevron back | ✅ |
| `accessibilityLabel="Volver"` | ✅ |
| AppInput maneja `accessibilityLabel` via `label` prop | ✅ |
| Input deshabilitado en Card 2: `editable={false}` + `pointerEvents="none"` | ✅ |
| Botón Actualizar `disabled={!canSubmit}` | ✅ |
| Touch target btn h-40 | ⚠️ Bajo 44 (M2-FE-02) |

---

## 🚧 Validación a nivel UX (mejor que solo Figma)

El gating del Card 2 + el botón disabled hasta `canSubmit === true` introducen 4 validaciones en runtime:

1. **Card 2 unlocked**: `currentPassword.length > 0`
2. **Nueva password con contenido**: `newPassword.length > 0`
3. **Confirma password con contenido**: `confirmPassword.length > 0`
4. **5 reglas de seguridad**: 8 chars + minúscula + mayúscula + número + carácter especial
5. **Match**: `newPassword === confirmPassword`

Solo cuando los 5 son verdad, el botón "Actualizar" se enciende (bg teal sólido vs disabled rgba 0.3).

Las reglas en vivo ayudan al usuario a entender qué falta sin tener que enviar y recibir error.

---

## 🏁 Veredicto

Refactor completo de la pantalla — pasó de UN card con todo a la estructura correcta del Figma (DOS cards con gating UX). Aplicadas las 2 correcciones tipográficas conocidas del Módulo 2 (`fontFamily.semiBold` en title, `fontFamily.display` en subtitle).

**Score 95/100.** Los 5 puntos restantes:
- Touch target btn h-40 (M2-FE-02, compartido)
- Requirements box no en Figma (divergencia consciente UX, no resta)
- Chevron size 28 vs 32 (issue marginal repetido en otras pantallas)

**Patrón nuevo aprendido (lo añadiré al skill):**
> **Gating UX entre cards**: cuando Figma muestra `opacity: 0.5` en un card, traducir como `cardDisabled` style + `pointerEvents="none"` + `editable={false}` en los inputs. Implementar lógica de validación al wrapper del screen para encender el botón submit solo cuando todos los campos son válidos.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-07 (#1) | 95/100 | Refactor: 1 card → 2 cards con gating opacity-50 hasta llenar Contraseña actual. Validación completa del botón Actualizar (5 reglas + match + 3 campos llenos). Requirements box ahora reactivo (visible solo si newPassword tiene contenido). |
| 2026-06-07 (#2) | 97/100 | Refactor del password validation reusando `/register`: removidas funciones inline `passwordRules` + `RuleRow` (~70 líneas), reemplazadas con `<PasswordHints>` compartido + `isPasswordSecure()` helper. Mejoras: (1) styling alineado con register/reset (mismos tokens Figma `#F8F4ED` bg + 3 reqs visibles), (2) Android focus-jump fix incluido (opacity swap CheckCircle2/X), (3) animación de altura interpolada (220ms) en vez de mount/unmount abrupto, (4) `LayoutAnimation.configureNext` en Android cuando cambia el layout del card. UI ahora muestra 3 reqs (8 chars + mayúscula + número) match register; backend valida 5 (mismo backend que register usa). |
