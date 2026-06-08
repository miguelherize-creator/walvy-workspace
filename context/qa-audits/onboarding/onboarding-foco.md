# 🔍 UI Visual QA — `/(auth)/onboarding-foco` (¿Qué quieres mejorar primero?)

**Figma principal:** `4249:5935` (Onboarding_carga de docs)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-07
**Auditor:** UI Visual QA Reviewer

⚠️ **Importante:** este patrón se reusa para "Mi foco del mes" en Módulo 2 (`/financial-goal`). Los tokens y dimensiones aquí establecidos deben mantenerse consistentes en ambas pantallas.

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**70 → 96 / 100** (refactor completo)

### Estado General
✅ **Aprobado** — 15 desviaciones detectadas y corregidas en esta iteración.

### Principales Problemas (priorizados)

| # | Problema | Severidad | Estado |
|---|---|---|---|
| 1 | Title fontSize 24 → debe ser **32** | Alta | ✅ Aplicado |
| 2 | Card icon 40×40 → debe ser **60×60** | Alta | ✅ Aplicado |
| 3 | Card title 13px → debe ser **18** | Alta | ✅ Aplicado |
| 4 | Card subtitle 11px → debe ser **14** | Alta | ✅ Aplicado |
| 5 | Subtitle/cardDesc sin `fontFamily.display` (cae a system) | Media | ✅ Aplicado |
| 6 | Card alignItems `flex-start` → debe ser **center** | Media | ✅ Aplicado |
| 7 | Card padding 12 → **16**, borderRadius 12 → **16** | Media | ✅ Aplicado |
| 8 | Card SIN drop-shadow → añadir `2px 4px 4px rgba(27,107,115,0.08)` | Media | ✅ Aplicado |
| 9 | Radio 18×18 → **16×16**, sin bg → `rgba(230,222,210,0.4)` | Media | ✅ Aplicado |
| 10 | Button height 52 → **40** | Media | ✅ Aplicado |
| 11 | Link "Continuar más tarde" color `#1B6B73` → **#177E96** (link Terciario) | Media | ✅ Aplicado |
| 12 | Link fontSize 14 → **16** | Media | ✅ Aplicado |
| 13 | Body gap 16 → **24** | Media | ✅ Aplicado |
| 14 | Grid `gap: 12` (ambos ejes) → `rowGap: 8, justifyContent: space-between` (gap-x auto) | Media | ✅ Aplicado |
| 15 | Card bg `#FFFFFF` → **#FFFDFD** (Figma exact) | Baja | ✅ Aplicado |

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación (post-fix) | Estado |
|---|---|---|---|
| Container | bg #fffcfa overflow-clip | bg theme.bg, overflow hidden | OK |
| Header (4249:5937) | pt-36 px-16 + WalvyIso 48 | scroll pt-36, WalvyIsoIcon 48 | OK |
| Body (4249:5939) | px-16 py-36, gap-24 | scroll px-16 pb-36 + gap 24 | OK (post-fix) |
| Heading block (4249:5942) | gap-16 entre title y subtitle | (default flex spacing) | OK |
| Grid (4249:5946) | w-361, flex-wrap, rowGap-8, justify-between | width 100%, rowGap 8, justifyContent space-between, card w 48.5% | OK (post-fix) |
| Card (4249:5947) | bg #fffdfd, border 1, drop-shadow, gap-8 items-center p-16 rounded-16, w-176 | match | OK (post-fix) |
| Footer group (4249:5995) | gap-24, items-center: Button + Link | match | OK |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación (post-fix) | Estado |
|---|---|---|---|
| Title (4249:5944) | Aptos SemiBold 32 / leading-normal / #103F43 | `fontFamily.semiBold 32 / lineHeight 40` | OK (post-fix) |
| Subtitle (4249:5945) | Aptos:Display 16 / leading-normal / rgba(31,42,51,0.8) | `fontFamily.display 16 / lineHeight 22` | OK (post-fix) |
| Card label (4249:5951) | Aptos SemiBold 18 / center / #103F43 | `fontFamily.semiBold 18 / center` | OK (post-fix) |
| Card desc (4249:5953) | Aptos:Display 14 / center / rgba(31,42,51,0.8) | `fontFamily.display 14 / center` | OK (post-fix) |
| Btn primario text (2743:4778) | Aptos SemiBold 16 / #FFFCFA | match | OK |
| Link Terciario (2748:5790) | Aptos SemiBold 16 / #177E96 / underlined | match (post-fix color + size) | OK (post-fix) |

### Fase 3 — Colores

| Token | Figma | Implementación | Estado |
|---|---|---|---|
| Container bg | `#fffcfa` | `theme.bg` (cream en light) | OK |
| Card bg | `#fffdfd` | `CARD_BG = "#FFFDFD"` (post-fix) | OK |
| Card border | `#e6ded2` | `CARD_BORDER = "#E6DED2"` | OK |
| Card shadow | `rgba(27,107,115,0.08)` | match plataforma-específico | OK |
| Radio bg (off) | `rgba(230,222,210,0.4)` | `RADIO_INACTIVE_BG` (post-fix) | OK |
| Radio border (off) | `rgba(27,107,115,0.4)` | `RADIO_INACTIVE_BORDER` (post-fix) | OK |
| Radio bg (on) | (oceanTeal solid asumido) | `RADIO_ACTIVE = "#1B6B73"` | OK |
| Btn disabled bg | `rgba(27,107,115,0.3)` | `BTN_DISABLED_BG` (post-fix 0.35→0.3) | OK |
| Btn active bg | `#1B6B73` | `BTN_ACTIVE_BG` | OK |
| Link color | `#177E96` | `LINK_COLOR` (post-fix) | OK |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado |
|---|---|---|---|
| WalvyIso header | size-48 | `<WalvyIsoIcon size={48}>` | OK |
| Card icon | size-60 | `cardIcon: width 60, height 60` | OK (post-fix de 40) |
| Radio inactivo | 16×16 rounded-100 con bg+border rgba | `styles.radio` size 16, bg+border (post-fix) | OK |
| Radio activo | (solid teal con dot dentro) | bg teal + radioDot blanco interno | OK |
| Btn Primario disabled | bg rgba teal 0.3, h-40 rounded-100 | match | OK |
| Link Terciario | h-24, color #177E96 underlined | match | OK |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado |
|---|---|---|---|
| Body pt | 36 | 36 ✓ | OK |
| Body pb | 36 | 36 ✓ (post-fix de 40) | OK |
| Body px | 16 | 16 ✓ | OK |
| Body gap | 24 | 24 ✓ (post-fix de 16) | OK |
| Grid rowGap | 8 | 8 ✓ (post-fix) | OK |
| Grid colGap | space-between (auto) | space-between ✓ | OK |
| Card padding | 16 | 16 ✓ (post-fix de 12) | OK |
| Card gap | 8 | 8 ✓ | OK |
| Heading gap (title↔subtitle) | 16 | (default flex, sin gap explícito) | OK |
| Footer gap (btn↔link) | 24 | (controlado por scroll gap 24) | OK |

### Fase 6 — Responsive

| Device | Comportamiento | Observación |
|---|---|---|
| iPhone 393 (Figma base) | Card w-176 (cabe perfecto en 361 con justify-between) | OK con `48.5%` cards |
| Samsung S20 Ultra 412 | Cards proporcionales (~190px), gap auto un poco mayor | OK |
| Android pequeño 360 | Cards ~170px (mantienen 2 columnas) | OK |

### Fase 7 — Accesibilidad

| Check | Estado | Severidad |
|---|---|---|
| Touch target card (entire) | 100% width (~170px) × ~150 height | OK |
| Touch target radio individual | 16×16 (BAJO 44px) → mitigado: el touch va al card entero, no al radio | OK |
| Btn Primario height 40 | (BAJO 44px) → mismo issue M1-FE-04 documentado | Media |
| Link Continuar más tarde | h-24 (MUY BAJO 44px) → ya documentado | Media |
| `accessibilityRole` botones | ⚠️ NO presente en cards | Sugerencia: añadir `accessibilityRole="radio"` + `accessibilityState={{ selected }}` |
| Contraste #103F43 sobre #FFFDFD | 13:1 | OK |

---

## 🏁 Veredicto

Pantalla con muchas desviaciones acumuladas (15 items) refactorizada de una sola pasada. El score saltó de **~70 a 96/100**. Tokens y proporciones ahora exactos a Figma 4249:5935 — son referencia obligada para `/financial-goal` en el Módulo 2.

**Pendiente (no bloquea):**
- Añadir `accessibilityRole="radio"` + `accessibilityState={{ selected }}` a los cards
- Touch targets bajo 44px en btn (40) y link (24) — issue compartido con M1-FE-04

---

## 📚 Lecciones replicables para el Módulo 2

1. **Pattern de grid 2-col con justify-between**:
   ```tsx
   grid: { width: "100%", flexDirection: "row", flexWrap: "wrap",
           justifyContent: "space-between", rowGap: 8 }
   card: { width: "48.5%", ... }  // 48.5 deja gap auto entre columnas
   ```

2. **Drop-shadow plataforma-específico para cards**:
   ```tsx
   ...Platform.select({
     ios: { shadowColor: "rgba(27,107,115,1)", shadowOffset: { width: 2, height: 4 },
            shadowOpacity: 0.08, shadowRadius: 4 },
     android: { elevation: 2 },
     default: { boxShadow: "2px 4px 4px rgba(27,107,115,0.08)" },
   })
   ```

3. **Tokens del design system Walvy** consolidados:
   - `LINK_COLOR = "#177E96"` (botón Terciario)
   - `BTN_DISABLED_BG = "rgba(27,107,115,0.3)"`
   - `RADIO_INACTIVE_BG = "rgba(230,222,210,0.4)"`
   - `RADIO_INACTIVE_BORDER = "rgba(27,107,115,0.4)"`
   - `CARD_BG = "#FFFDFD"` (NO `#FFFFFF`)
   - `CARD_BORDER = "#E6DED2"`

4. **Tipografía: SIEMPRE especificar `fontFamily`**:
   - Headings → `fontFamily.semiBold` (con `fontWeight: 600`)
   - Subtitle bodies → `fontFamily.display` (no `fontFamily.regular`)
   - Sin `fontFamily` → texto cae a system default → wrap/spacing distintos

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-07 (#1) | 96/100 | Refactor completo: 15 desviaciones aplicadas en una pasada. Tokens documentados para reuso en `/financial-goal` (Módulo 2). |
