# 🔍 UI Visual QA — `/register` (RegisterScreen)

**Figma principal:** `3604:4273` (estado completo all-valid)
**Figma estado filled:** `3604:4169` (campos llenos, checkboxes sin marcar)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-30
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**92 / 100** *(↑ +7 desde la auditoría inicial 85/100)*

### Estado General

✅ **Aprobado con observaciones**

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | Helper "Lo usamos para identificar tu cuenta." sigue visible cuando el RUT es válido (Figma 3604:4273 lo oculta en estado all-valid) | Media |
| 2 | Tamaño táctil de los 4 links subrayados (24px alto): "términos y condiciones", "Política de privacidad", "Inicia sesión" — por debajo de 44px | Media |
| 3 | "Inicia sesión" font size: 14px vs **16px** del Figma | Baja |
| 4 | Label "Contraseña": SemiBold (Figma usa Regular para ese label específico) | Baja |
| 5 | Botón "Crear mi cuenta" usa `width: 100%` en vez de `w-361` fijo del Figma | Baja |
| 6 | Subtítulo wrappea en 2 líneas en Android vs 1 línea en Figma (viewport más angosto) | Baja |
| 7 | Bandera CL RUT: `24×16` vs `18×11` del Figma | Baja |
| 8 | Icono ojo password: `20×20` vs `18×16` del Figma | Baja |
| 9 | `py main` 32px vs 36px del Figma | Baja |

---

### Recomendaciones

#### Prioridad Media

- **Ocultar el helper RUT cuando el RUT sea válido**
  - Ajustar condición: `{!rutError && !isRutValid && <Text>Lo usamos...</Text>}`
  - El estado Figma 3604:4273 confirma que el helper desaparece cuando todos los campos pasan validación

- **Aumentar área táctil de los 4 links subrayados** a mínimo 44px
  - `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}` en cada `Pressable`

#### Prioridad Baja

- **"Inicia sesión":** font size `14 → 16px` para coincidir con Figma
- **Label "Contraseña":** evaluar inconsistencia tipográfica del Figma (Regular). Si no es intencional, mantener SemiBold
- **Botón "Crear mi cuenta":** `width: 361, alignSelf: "center"` o `maxWidth: 361`
- **Bandera CL:** ajustar a `18×11`
- **Icono ojo password:** `size={20}` → `size={18}` cuando `figmaLogin={true}`
- **`py main`:** `32 → 36px`

---

## ✅ Logros del fix #1 (PasswordHints inside card)

| Mejora | Antes (auditoría #1) | Ahora (auditoría #2) |
|---|---|---|
| Box "Requisitos" posición | FUERA del card | **DENTRO del card** ✅ |
| Card interno gap | `gap-8` flat | `gap-16` con `inputGroup` anidado ✅ |
| Estructura visual del card | Inputs flotando, box separado | Card unificado igual a Figma ✅ |
| Pixel Perfect Score | 85/100 | **92/100** ✅ |

**Solución técnica aplicada:** `Animated.View` con altura interpolada (0 ↔ 108px) que envuelve `PasswordHints`. Mantiene fidelidad al Figma sin reintroducir el bug de focus jumping en Android (3 capas de protección: Animated transition + opacity icon toggle + elevation removida del error state).

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Logo: posición y align | Top-left, `pt-36 px-16`, `220×82` | Top-left | OK | — |
| Box "Requisitos" posición | DENTRO del card | DENTRO del card | OK ✅ FIX APLICADO | — |
| Card estructura interna | `gap-16` entre inputGroup y box | Match ✅ | OK | — |
| Input group interno | `gap-8` entre 4 inputs | Match ✅ | OK | — |
| Helper RUT visibilidad | NO mostrado (estado all-valid) | Mostrado siempre que no haya error | Diferencia Media | Media |
| Bandera CL pos | absolute derecha del label RUT | Inline a la derecha del label | OK | — |
| Subtítulo wrap | 1 línea | 2 líneas | Diferencia Menor | Baja |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title "Crea tu cuenta en Walvy" | Aptos SemiBold 24px lh-32 | Match | OK | — |
| Subtitle | Aptos Display 16px lh-16 | Match | OK | — |
| Label "Correo electrónico" | Aptos SemiBold 12px | Match | OK | — |
| Label "Confirma tu correo" | Aptos SemiBold 12px | Match | OK | — |
| Label "RUT" | Aptos SemiBold 12px | Match | OK | — |
| Label "Contraseña" | Aptos **Regular** 12px tracking-0.6 | SemiBold 12px | Diferencia Menor | Baja |
| Input text filled | Aptos SemiBold 16px `#103F43` no italic | Match | OK | — |
| Heading "Requisitos…" | Manrope Bold 12px lh-24 | Match | OK | — |
| Item requisito | Aptos Regular 12px rgba(31,42,51,0.8) | Match | OK | — |
| Checkbox label "Acepto los" | Aptos Regular 14px `#005259` | Match | OK | — |
| Link "términos…" / "Política…" | Aptos SemiBold 14px `#177E96` underline | Match | OK | — |
| Botón "Crear mi cuenta" texto | Aptos SemiBold 16px `#FFFCFA` | Match | OK | — |
| "¿Ya tienes cuenta?" | Aptos Display 12px rgba(31,42,51,0.8) | Match | OK | — |
| **"Inicia sesión"** | Aptos SemiBold **16px** `#177E96` underline | SemiBold **14px** | Diferencia Menor | Baja |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Background pantalla | `#fffcfa` | Match | OK | — |
| Title color | `#103f43` | Match | OK | — |
| Subtitle color | `rgba(31,42,51,0.8)` | Match | OK | — |
| Card bg | `#fffdfd` | Match | OK | — |
| Card border | `#e6ded2` | Match | OK | — |
| Card shadow | `2px 4px 4px rgba(27,107,115,0.08)` | Match | OK | — |
| Input border filled | `#1b6b73` | Match ✅ | OK | — |
| Input text filled | `#103f43` | Match | OK | — |
| Box requisitos bg | `#f8f4ed` | Match | OK | — |
| Box requisitos border | `#e6ded2` | Match | OK | — |
| Checkbox bg CHECKED | `#1b6b73` solid | Match ✅ | OK | — |
| Check icon color | blanco | `#FFFCFA` blanco | OK | — |
| Checkbox label color | `#005259` | Match | OK | — |
| Link color | `#177e96` | Match | OK | — |
| Botón "Crear mi cuenta" ENABLED | `#1b6b73` solid | Match ✅ | OK | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Card | rounded-16, p-16, gap-16, shadow | Match ✅ FIX APLICADO | OK | — |
| Input wrapper | h-52, rounded-8, p-16, border-1 | Match | OK | — |
| Eye icon (password) | `18×16`px | `20×20` (lucide) | Diferencia Menor | Baja |
| Box requisitos | rounded-8, px-16 py-8 | Match | OK | — |
| Item requisito icono | `16×16` circle-check | `16×16` CheckCircle2 | OK | — |
| Checkbox CHECKED | `16×16`, bg `#1B6B73`, white check | Match | OK | — |
| Link wrapper "términos…" | rounded-100, px-8 py-12.5, h-24 | minHeight táctil sin rounded explícito | Diferencia Menor | Baja |
| Botón "Crear mi cuenta" | h-40, rounded-100, w-361 fijo | h-40, rounded-100, width 100% | Diferencia Menor | Baja |
| Bandera CL RUT | 18×11 PNG | 24×16 PNG con border-radius | Diferencia Menor | Baja |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| pt header (logo) | `36px` | `32px` | Diferencia Menor | Baja |
| Title ↔ Subtitle gap | 0px (lh separa) | 0px | OK | — |
| Subtitle → Card | `gap-16` del main | `gap: 24` del scroll | Diferencia Menor | Baja |
| Card → Checkboxes | `gap-16` del main | `gap: 24` del scroll | Diferencia Menor | Baja |
| Card interno (inputGroup → box) | `gap-16` | `gap: 16` ✅ FIX APLICADO | OK | — |
| Inputs internos | `gap-8` | `gap: 8` | OK | — |
| CTA group | `gap-24` | Match | OK | — |
| Checkbox → label | `gap-6` | `gap: 6` | OK | — |
| Px container | `16px` | `16px` | OK | — |
| Py main | `36px` | `32px` | Diferencia Menor | Baja |

### Fase 6 — Responsive

| Aspecto | Figma | Implementación (Android Samsung) | Estado | Severidad |
|---|---|---|---|---|
| Viewport reference | 393×926 | ~360×~780 dp | OK | — |
| Status bar | No visible | Visible | OK | — |
| Card width | Full-width px-16 | Full-width px-16 | OK | — |
| Sin overflow | n/a | Sin overflow | OK | — |
| Subtítulo wrap | 1 línea | 2 líneas | Diferencia Menor | Baja |
| Box requisitos width | Igual al card (dentro) | Igual al card (dentro) ✅ | OK | — |
| Botón Crear mi cuenta width | 361px fijo | 100% del container | Diferencia Menor | Baja |

### Fase 7 — Accesibilidad

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste title | 13.4:1 | Idéntico | OK | — |
| Contraste subtitle | 7.1:1 | Idéntico | OK | — |
| Contraste input text filled | 11.2:1 | Idéntico | OK | — |
| Contraste checkbox label | 8.4:1 (#005259) | Idéntico | OK | — |
| Contraste botón ENABLED | 6.8:1 (#1B6B73/#FFFCFA) | Idéntico ✅ | OK | — |
| Tamaño táctil checkbox | 16px | 16px | Diferencia Media | Media |
| Tamaño táctil link "términos…" | 24px alto | 24px alto | Diferencia Media | Media |
| Tamaño táctil link "Política…" | 24px alto | 24px alto | Diferencia Media | Media |
| Tamaño táctil link "Inicia sesión" | 24px alto | 24px alto | Diferencia Media | Media |
| Tamaño táctil botón Crear cuenta | 40px | 40px | Diferencia Menor | Baja |
| Jerarquía visual | Title > Subtitle > Labels > Inputs > Box req > Checkboxes > CTA | Match | OK | — |

---

## 🏁 Veredicto

Pantalla de registro con altísima fidelidad después del fix de PasswordHints inside the card. La única observación nueva de severidad Media es el **helper RUT que debería ocultarse en estado valid**.

**Próximas acciones recomendadas (en orden de prioridad):**

1. Ocultar helper RUT cuando `isRutValid && !rutError`
2. Aumentar `hitSlop` de los 4 links subrayados
3. Corregir "Inicia sesión" a 16px
4. Resto: deuda técnica menor

Con esos 3 fixes, el score subiría a ~97/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-30 (#1) | 85/100 | PasswordHints fuera del card (fix para Android focus jump) |
| 2026-05-30 (#2) | **92/100** | ✅ Fix aplicado: PasswordHints dentro del card vía `Animated.View` |
