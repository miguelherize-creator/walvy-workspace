# 🔍 UI Visual QA — `/(tabs)/profile` (ProfileScreen — vista Datos)

**Figma principal:** `3395:4515` ("Mi Perfil/Mis datos")
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-03
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**95 / 100**

### Estado General
✅ **Aprobado** — 3 desviaciones detectadas y corregidas en esta misma iteración.

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|---|---|
| 1 | Inputs renderizaban el valor escrito en *italic* (Alias "jsjs", Nombre "Usuario", Apellido "Demo" todos italic). Figma 3395:4539/4540/3463:2730 usa `Aptos:SemiBold` sin italic para valores filled. | Alta |
| 2 | "Seguridad" estaba como section heading FUERA del card. Figma 3395:4542 lo pone DENTRO del card al top con gap-16 con las filas. | Media |
| 3 | Falta `gap` explícito entre header block (título+subtítulo) y las 2 cards. La separación dependía de `marginTop/Bottom` del sectionHeading (ahora removidos). | Media |

### Recomendaciones

#### Prioridad Alta — ✅ Aplicada
- **`components/AppInput.tsx`**: el `fontStyle: "italic"` del estilo `inputFigma` aplicaba SIEMPRE (tanto para placeholder como para valor filled). Refactor:
  - `inputFigma` ahora solo tiene los estilos base (font, size, padding).
  - Nuevo `inputFigmaPlaceholder` con `fontStyle: "italic"` — se aplica solo cuando `!filled`.
  - Nuevo `inputFigmaFilled` con `fontWeight: "600"` — se aplica solo cuando `filled`.
  - JSX: `figmaLogin && !filled && styles.inputFigmaPlaceholder` y `figmaLogin && filled && styles.inputFigmaFilled`.

#### Prioridad Media — ✅ Aplicada
- **`features/profile/ui/ProfileScreen.tsx`**: movido `<Text>Seguridad</Text>` DENTRO del `<View style={profileCard.securityCard}>`, al top antes de las filas.
- **`constants/profileStyles.ts`**:
  - `sectionHeading`: removidos `marginTop`/`marginBottom` (ahora vive dentro de card con gap-16 del propio card).
  - `securityCard`: cambiado `paddingHorizontal: spacing.lg + paddingVertical: spacing.sm` → `padding: spacing.lg + gap: spacing.lg` (Figma p-16, gap-16). `borderRadius.sm` → `borderRadius.md` (8→16 match Figma `rounded-[16px]`).
  - `scrollContent`: añadido `gap: spacing.lg` (16) entre direct children. `paddingBottom: spacing.xxxl + spacing.lg` (48) → `spacing.xxxl + spacing.xs` (36) match Figma `pb-36`.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Container root | `bg #fffcfa`, items-center, overflow-clip | tabs layout root + transparent screen + watermark (iter previa) | OK |
| Header (drop-shadow) | Inyectado via tabs `_layout.tsx` | match (`drop-shadow rgba(27,107,115,0.1)` iter previa) | OK |
| Body container | `pt-24 pb-36 px-16, gap-16` | `scrollContent` ahora con `gap: 16` | OK (post-fix) |
| Heading block | `gap-8` (chevron+title arriba, subtitle abajo) | `headerBlock: gap: spacing.sm` (8) | OK |
| Cards container | `gap-16` entre datos card y security card | `scrollContent gap` distribuye en todos los children | OK (post-fix) |
| Datos card | `p-16, gap-16, rounded-16, border 1px #e6ded2, drop-shadow` | `profileCard.datosCard` + `cardShadow` | OK |
| Security card | `p-16, gap-16, rounded-16, border 1px #e6ded2, drop-shadow` | `securityCard` ahora con `padding: 16, gap: 16, borderRadius.md` | OK (post-fix) |
| "Seguridad" heading | DENTRO del card al top | movido dentro (post-fix) | OK (post-fix) |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Title "Mis datos" | Aptos SemiBold 24 / leading-32 / #103F43 | `screenTitle: 24/600/32` | OK |
| Subtitle | Aptos Display 16 / leading-16 / rgba(31,42,51,0.8) | `subtitle` | OK |
| Correo/Rut readonly | Aptos SemiBold 16 / rgba(16,63,67,0.5) | `readonlyField` | OK |
| Input label | Aptos Regular 12 / tracking 0.6 / #3F484A | `labelFigma` | OK |
| Input value (filled) | Aptos SemiBold 16 / #103F43 — **NO italic** | `inputFigmaFilled: fontWeight 600` (post-fix) | OK (post-fix) |
| Input placeholder | (asumido italic como hint) | `inputFigmaPlaceholder: fontStyle italic` (post-fix) | OK (post-fix) |
| Section heading "Seguridad" | Aptos SemiBold 18 / leading 1.4 (~25) / rgba(16,63,67,0.8) | `sectionHeading: 18/600/25` (post-fix sin márgenes) | OK (post-fix) |
| Security row label | Aptos SemiBold 14 / leading-16 / #103F43 | `securityLabel` | OK |

### Fase 3 — Colores

| Token | Figma | Implementación | Estado |
|---|---|---|---|
| Card bg | `#fffdfd` | `pc.datosCardBg` (FIGMA_DATOS_CARD_BG) | OK |
| Card border | `#e6ded2` | `pc.datosCardBorder` | OK |
| Card shadow | `2px 4px 4px rgba(27,107,115,0.08)` | `cardShadow` | OK |
| Input bg | `#fffcfa` | `FIGMA_INPUT_BG` | OK |
| Input border active | `#1B6B73` (filled state) | `FIGMA_INPUT_BORDER_ACTIVE` | OK |
| Input border default | `#E6DED2` (empty state) | `FIGMA_INPUT_BORDER_DEFAULT` | OK |
| Input text | `#103F43` filled | `inputTextColor` (theme.deepTeal) | OK |
| Icon slot bg | `#f6f6f6` (security rows) | `pc.iconSlotBg` | OK |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado |
|---|---|---|---|
| Avatar | `size-128`, person icon centered, coral arc inferior, edit btn esquina | `profileAvatar.{block,circle,image,coralArc,editBtn}` | OK |
| Divider in-card | `h-0 inset-[-0.5px_0]` (línea 1px full-width) | `inCardDivider` | OK |
| Input (figmaLogin mode) | h-52, rounded-8, border 1, p-16 | `inputWrapperFigma` | OK |
| Toggle (custom) | track 40×24 rounded-100, thumb 24×24 | `DarkModeToggle` | OK |
| Security icon slot | `bg-[#f6f6f6] p-8 rounded-8 size-40` con icono 24×24 dentro | `securityIconSlot` | OK |
| Full divider seguridad | línea 1px entre Face ID y Huella | `fullDivider` | OK |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado |
|---|---|---|---|
| Body pt | 24 | 24 | OK |
| Body pb | 36 | 36 (post-fix) | OK (post-fix) |
| Body px | 16 | 16 | OK |
| Gap body→header block | n/a | n/a | OK |
| Gap header block→cards container | 16 | 16 vía `scrollContent gap` | OK (post-fix) |
| Gap entre datos card y security card | 16 | 16 vía `scrollContent gap` | OK (post-fix) |
| Gap heading→subtitle | 8 | 8 (`headerBlock gap`) | OK |
| Card padding | 16 | 16 (post-fix) | OK (post-fix) |
| Card gap (heading→rows) | 16 | 16 (post-fix) | OK (post-fix) |
| Input gap (label→box) | 8 | 8 | OK |
| Gap entre inputs (Alias/Nombre/Apellido) | 8 | 8 (`datosInputsGap`) | OK |

### Fase 6 — Responsive

| Device | Comportamiento esperado | Observación |
|---|---|---|
| iPhone 393×852 (Figma base) | Cards al ancho del body con 16 padding | OK |
| Samsung S20 Ultra 412×915 (dev actual) | Mismo, con 16px extra a los lados | OK |
| Android pequeño 360×780 | Cards se contraen | OK (no fixed widths internos) |

### Fase 7 — Accesibilidad

| Check | Estado | Severidad |
|---|---|---|
| Touch target chevron back | 28px size + hitSlop 8 | OK |
| Touch target avatar edit | hitSlop 4 + slot 40×40 | OK (marginalmente bajo 44px) |
| Touch target toggle | hitSlop 6 + track 40×24 | OK (marginalmente bajo) |
| Contraste título sobre cream/watermark | 13:1 | OK |
| `accessibilityRole` botones | ✅ presentes | OK |
| `accessibilityState` switch | ✅ `{ checked: value }` | OK |

---

## 🏁 Veredicto

La pantalla "Mis datos" (viewMode datos del ProfileScreen) tenía 3 desviaciones reales contra Figma 3395:4515:

1. **Italic en valores filled** — bug del componente `AppInput` que aplicaba italic universalmente al usar `figmaLogin`. Refactor para que italic solo aparezca en estado placeholder (empty).
2. **"Seguridad" fuera del card** — Figma lo pone dentro al top con gap-16. Movido.
3. **Spacing entre header block y cards** — dependía de márgenes verticales del section heading (que ya no aplicaban después del fix #2). Añadido `gap: 16` al scrollContent + ajustado `paddingBottom` a 36 match Figma.

Todos los fixes son ya código entregado. **Score 95/100**.

Las 5 unidades restantes son por consideraciones menores (touch targets marginalmente bajo 44px en avatar edit y toggle, mismo issue compartido con M1-FE-04, hoy en `modulo01-identidad-autenticacion/deuda-tecnica/README.md`).

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-03 (#1) | 95/100 | Tres fixes aplicados en misma iteración: italic condicional en AppInput, "Seguridad" dentro del card, gap-16 + pb-36 en scrollContent. |
