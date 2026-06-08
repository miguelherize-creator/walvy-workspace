# 🔍 UI Visual QA — `/(tabs)/financial-goal` (Mi foco del mes)

**Figma principal:** `3993:5216` (Mi Perfil/Foco del mes)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-07
**Auditor:** UI Visual QA Reviewer (Module 2 — primera aplicación del patrón de Onboarding Foco)

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**Construido desde cero: 95 / 100**

### Estado General
✅ **Aprobado** — La pantalla anterior era un placeholder vacío ("primero necesitas llenar tu perfil financiero"). Reescrita por completo replicando el patrón de selección de foco de `OnboardingFocoScreen`.

### Patrón reusado del Módulo 1 (Onboarding)

| Pattern | Origen | Adaptación en /financial-goal |
|---|---|---|
| Grid 2-col 48.5% + justify-between + rowGap-8 | onboarding-foco | Idéntico |
| Card bg #FFFDFD + border + drop-shadow 0.08 teal | onboarding-foco | Idéntico |
| Card icon 60×60 + Aptos SemiBold 18 + Display 14 | onboarding-foco | Idéntico |
| Radio 16×16 con bg rgba(230,222,210,0.4) + border rgba(27,107,115,0.4) | onboarding-foco | Idéntico |
| FOCOS array (6 opciones con images de `assets/images/goals/`) | onboarding-foco | Duplicado por ahora (puede extraerse a shared module si aparece 3er uso) |
| FocoCard component | onboarding-foco | Duplicado con `accessibilityRole="radio"` añadido |

### Diferencias del Módulo 1 (Onboarding) → Módulo 2 (Mi perfil)

| Aspecto | Onboarding | Mi foco del mes (este screen) |
|---|---|---|
| Title fontSize | 32 | **24** |
| Title con chevron back | NO (centrado) | **SÍ** (chevron + title row) |
| Body pt | 36 | **24** |
| Heading layout | gap-16 con sub-container | **gap-8 directo** title-row + subtitle |
| Subtitle texto | "Elige un foco para que Walvy te muestre una lectura y los próximos pasos más útiles para ti." | "Elige tu foco y dale un propósito a cada peso." |
| Link "Continuar más tarde" | SÍ (botón Terciario) | **NO** |
| Header del app (WalvyIso + bell + avatar) | NO (standalone screen) | **SÍ** (inyectado por tabs layout) |
| Bottom nav | NO | **SÍ** (inyectado por tabs layout) |
| Watermark de fondo | Background blob propio | Watermark global del tabs layout |

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Tabs header (4239:2422-equiv) | drop-shadow teal + WalvyIso + bell + avatar | Inyectado vía `(tabs)/_layout.tsx → HomeHeader` | OK |
| Body container (3993:5219) | pb-36 pt-24 px-16, gap-24 | `scroll: { pt: 24, pb: 36, px: 16, gap: 24 }` | OK |
| Heading block (3993:5220) | gap-8 entre titleRow y subtitle | `headingBlock: { gap: 8, width: "100%" }` | OK |
| Title row (3993:5221) | chevron 32 + title alineados horizontalmente | `titleRow: { row, alignItems: center, gap: 4 }` | OK |
| Grid (3993:5227) | w-361, flex-wrap, rowGap-8, justify-between | `grid: { width: "100%", flexWrap, justifyContent: "space-between", rowGap: 8 }` con card `width: "48.5%"` | OK |
| Card (3993:5228) | bg #fffdfd, border, drop-shadow, gap-8 items-center p-16 rounded-16, w-176 | match (mismo style que onboarding-foco) | OK |
| Botón Guardar | h-40, w-full, bg #1B6B73 active / rgba(27,107,115,0.3) disabled | match | OK |
| Bottom nav | Inyectado por tabs layout | OK | OK |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Title (3993:5224) | Aptos SemiBold 24 / leading-32 / #103F43 | `fontFamily.semiBold 24 / 32` | OK |
| Subtitle (3993:5226) | Aptos:Display 16 / leading-normal / rgba(31,42,51,0.8) | `fontFamily.display 16 / 22` | OK |
| Card label (3993:5232) | Aptos SemiBold 18 / center / #103F43 | `fontFamily.semiBold 18 / center` | OK |
| Card desc (3993:5234) | Aptos:Display 14 / center / rgba(31,42,51,0.8) | `fontFamily.display 14 / center` | OK |
| Btn text (2743:4776) | Aptos SemiBold 16 / #FFFCFA | match | OK |

### Fase 3 — Colores

Idénticos al audit de `onboarding-foco.md` (mismos 9 tokens del design system documentados en el skill).

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado |
|---|---|---|---|
| Chevron back (3993:5222) | size-32 | `<ChevronLeft size={28}>` lucide | OK (4px diff, marginal) |
| Card icons (4160:4058-73) | image-{106-111} 60×60 (assets PNG) | `cardIcon: 60×60` con assets de `goals/` | OK |
| Radio (3223:975) | 16×16 con bg+border rgba | match | OK |
| Btn primario (2748:5834) | bg #1B6B73 active / rgba(27,107,115,0.3) disabled | match con dynamic backgroundColor | OK |

### Fase 5 — Espaciado

Idéntico al onboarding-foco salvo:
- Body pt: 24 (vs 36 del onboarding) — match Figma
- Heading gap: 8 (vs gap-16 del onboarding nested) — match Figma

### Fase 6 — Responsive

Cards de 48.5% width → siempre 2 columnas. Funciona en cualquier device ≥320px.

### Fase 7 — Accesibilidad

| Check | Estado |
|---|---|
| `accessibilityRole="radio"` en cards | ✅ Añadido (mejor que onboarding) |
| `accessibilityState={{ selected }}` | ✅ Añadido |
| `accessibilityLabel` descriptivo en cards | ✅ "Bajar deuda: Libera tus finanzas y reduce intereses." |
| `accessibilityRole="button"` en btn save | ✅ |
| `accessibilityState={{ disabled }}` en btn save | ✅ |
| `accessibilityLabel="Volver"` en chevron back | ✅ |
| Touch target btn h-40 | ⚠️ Bajo 44 (M2-FE-02) |

---

## 🚧 Pendiente backend (no afecta UI)

- **M2-DT-02** — Endpoints `/profile/goals` no implementados. El save actualmente solo hace `console.log + router.back()`. Cuando exista el endpoint:
  - Mutar via React Query: `POST /profile/goals { goalType: selected }`
  - Mostrar toast/success antes del `router.back()`
  - Cargar el foco actual del usuario al abrir la pantalla (preselección)

---

## 🏁 Veredicto

Pantalla construida desde cero (era placeholder vacío) replicando 1:1 el patrón establecido en `onboarding-foco.md` con las 5 adaptaciones específicas del Figma 3993:5216:
1. Title 24 (no 32) + chevron back
2. Body pt-24 (no 36)
3. Heading gap-8 plano (no nested)
4. Sin link "Continuar más tarde"
5. Vive dentro de tabs layout (header + bottom nav inyectados)

**Score 95/100.** Los 5 puntos restantes son:
- Backend persistence (M2-DT-02) — no afecta UI
- Touch target btn h-40 (M2-FE-02) — issue compartido del módulo

**Validación de la metodología:** el audit de `onboarding-foco.md` + las nuevas secciones del skill (`Grid 2-column con justify-between` + `Tokens del design system`) sirvieron para construir esta pantalla **en una sola pasada sin iteraciones**. Patrón confirmado.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-07 (#1) | 95/100 | Reescrita desde cero (era placeholder). Patrón de `onboarding-foco.md` aplicado con 5 adaptaciones documentadas. Pendiente backend M2-DT-02 para persistencia real. |
| 2026-06-07 (#2) | 96/100 | Añadido estado CONFIRMADO (Figma 3993:5304). Al presionar "Guardar mi foco" la screen transiciona a card grande (icon 128×128 + descripción + tagline "Walvy te guiará con la Ruta X..."). Link "Cambiar mi foco" (Botón Terciario #177E96 underlined) regresa al modo selección con el foco pre-seleccionado. Borde del card cambia a teal #1B6B73 + shadow opacity 0.3 (vs 0.08 del grid) para indicar "estado seleccionado". |
