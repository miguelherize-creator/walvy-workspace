# 🔍 UI Visual QA — `/login` (LoginScreen)

**Figma:** `3470:6974` — `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-30
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**94 / 100**

### Estado General

✅ **Aprobado con observaciones**

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | Tamaño táctil del link "¿Olvidaste tu contraseña?" (24px alto) por debajo del mínimo recomendado de 44px | Media |
| 2 | Botón "Entrar" usa `width: 100%` en vez de `w-361px` fijo del Figma | Baja |
| 3 | Icono ojo del password: `20×20` en lugar de `18×16` del Figma | Baja |
| 4 | Label "Contraseña": SemiBold (Figma usa Regular específicamente en este label) | Baja |
| 5 | Espacio Subtítulo → Card: `marginBottom: 36` fijo en vez de `flex-1` elástico | Baja |
| 6 | Wrapper del link "¿Olvidaste…?" sin `rounded-100` ni padding del Figma | Baja |

---

### Recomendaciones

#### Prioridad Media

- **Aumentar área táctil del link "¿Olvidaste tu contraseña?"** a mínimo 44px de alto
  - Opción A: `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}` al `Pressable`
  - Opción B: cambiar el wrapper para tener `paddingVertical: 12`

#### Prioridad Baja

- **Botón "Entrar":** usar `width: 361, alignSelf: "center"` o `maxWidth: 361` con `width: "100%"` para que coincida con Figma en viewports anchos.
- **Icono ojo:** reducir `size={20}` → `size={18}` en `<Eye>` / `<EyeOff>` cuando `figmaLogin={true}`.
- **Label "Contraseña":** evaluar si la inconsistencia tipográfica del Figma (Regular vs SemiBold) es intencional. Si no, dejar SemiBold consistente con Correo.
- **Espacio vertical:** envolver el bloque "subtítulo + card" con `flex: 1` y `justifyContent: "space-between"` para replicar comportamiento elástico del Figma.
- **Wrapper "¿Olvidaste…?":** añadir `borderRadius: 100, paddingHorizontal: 8, paddingVertical: 12.5` al `Pressable`.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Logo: posición y align | Top-left, `pt-36 px-16`, `220×82` | Top-left, mismo padding | OK | — |
| Welcome block align | `items-start` sin gap interno | Idéntico | OK | — |
| Card align horizontal | Centrado, full-width con padding-16 | Idéntico | OK | — |
| Card position vertical | Mid-low (justify-between, flex-1) | Ligeramente más arriba | Diferencia Menor | Baja |
| Espacio subtítulo → Card | ≈130px (variable por flex-1) | ≈100-110px | Diferencia Menor | Baja |
| Distribución general | Hero / Form / Footer | Idéntica | OK | — |
| Footer "¿Primera vez…?" | Centrado, parte inferior | Centrado, parte inferior | OK | — |
| Inputs gap dentro de card | `gap-8` | Idéntico | OK | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title "Te damos la bienvenida" | Aptos SemiBold 24px lh-32 | SemiBold 24px lh-32 | OK | — |
| Subtitle | Aptos Display 16px lh-16 w-400 | Display 16px lh-16 | OK | — |
| Label "Correo electrónico" | Aptos SemiBold 12px tracking-0.6 | SemiBold 12px | OK | — |
| Label "Contraseña" | Aptos Regular 12px | SemiBold 12px | Diferencia Menor | Baja |
| Placeholder text | Aptos Display Italic 16px | Display Italic 16px | OK | — |
| Botón "Entrar" texto | Aptos SemiBold 16px | SemiBold 16px | OK | — |
| "¿Olvidaste tu contraseña?" | Aptos SemiBold 12px underline | SemiBold 12px underline | OK | — |
| "¿Primera vez en Walvy?" | Aptos Display 12px lh-16 | Display 12px lh-16 | OK | — |
| "Crea mi cuenta" | Aptos SemiBold 14px underline | SemiBold 14px underline | OK | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Background pantalla | `#fffcfa` (crema) | `#FFFCFA` | OK | — |
| Title color | `#103f43` (deepTeal) | `#103F43` | OK | — |
| Subtitle color | `rgba(31,42,51,0.8)` | `rgba(31,42,51,0.8)` | OK | — |
| Card background | `#fffdfd` | `#FFFDFD` | OK | — |
| Card border | `#e6ded2` | `#E6DED2` | OK | — |
| Card shadow | `2px 4px 4px rgba(27,107,115,0.08)` | shadow teal 8% offset(2,4) radius 4 | OK | — |
| Input bg | `#fffcfa` | `#FFFCFA` | OK | — |
| Input border default | `#e6ded2` | `#E6DED2` | OK | — |
| Placeholder color | `rgba(16,63,67,0.6)` | `rgba(16,63,67,0.6)` | OK | — |
| Label color | `#3f484a` | `#3F484A` | OK | — |
| Eye icon color | dark teal | Match (lucide) | OK | — |
| Botón Entrar disabled | `rgba(27,107,115,0.3)` | `rgba(27,107,115,0.3)` | OK | — |
| Botón texto blanco | `#fffcfa` | `#FFFCFA` | OK | — |
| Link color | `#177e96` (oceanTeal) | `#177E96` | OK | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Card | rounded-16, p-16, gap-8, border-1 | Match | OK | — |
| Input wrapper | h-52, rounded-8, p-16, border-1 | Match | OK | — |
| Eye icon (password) | `18×16`px | `20×20` (lucide size=20) | Diferencia Menor | Baja |
| Botón Entrar | h-40, rounded-100, w-361 fijo | h-40, rounded-100, width 100% | Diferencia Menor | Baja |
| Botón "¿Olvidaste…?" wrapper | rounded-100, px-8 py-12.5, h-24 | minHeight: 24 sin padding rounded | Diferencia Menor | Baja |
| Botón "Crea mi cuenta" wrapper | rounded-100, px-8 py-12.5, h-24 | Match | OK | — |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| pt header (logo) | `36px` | `36px` | OK | — |
| Logo → Welcome block | ≈36px | `marginBottom: 36` welcomeBlock | OK | — |
| Title ↔ Subtitle gap | 0px (lineheight separa) | 0px | OK | — |
| Subtitle → Card | flex-1 elastic (~120-140px) | `marginBottom: 36` fijo | Diferencia Menor | Baja |
| Card → Botón Entrar | `gap-40` form | `gap: 40` form | OK | — |
| Botón → "¿Olvidaste…?" link | `gap-24` ctaGroup | `gap: 24` ctaGroup | OK | — |
| "¿Olvidaste…?" → footer | flex-1 (pt-60 mínimo) | `paddingTop: 60` | OK | — |
| Footer prompt → link | `gap-4` interno | `gap: 4` interno | OK | — |
| px container | `16px` | `16px` | OK | — |
| pb container | `36px` | `36px` | OK | — |

### Fase 6 — Responsive

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Viewport reference | 393×852 (iPhone 14) | ~360×~780 dp (Samsung) | OK | — |
| Status bar | No visible en Figma | Visible (iconos sistema) | OK | — |
| Card width | Full-width con px-16 | Full-width con px-16 | OK | — |
| Sin overflow / scroll cortado | n/a | Sin overflow visible | OK | — |
| Text wrap subtítulo | 2 líneas | 2 líneas | OK | — |

### Fase 7 — Accesibilidad

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste title | 13.4:1 | Idéntico | OK | — |
| Contraste subtitle | 7.1:1 | Idéntico | OK | — |
| Contraste placeholder | 3.2:1 (italic, OK para placeholder) | Idéntico | OK | — |
| Contraste botón disabled | 1.8:1 (esperado) | Idéntico | OK | — |
| Tamaño táctil botón Entrar | 40px (mínimo 44 recomendado) | 40px | Diferencia Menor | Baja |
| Tamaño táctil link "¿Olvidaste…?" | 24px alto | 24px alto | Diferencia Media | Media |
| Jerarquía visual | Title > Subtitle > Labels > Placeholder | Match | OK | — |

---

## 🏁 Veredicto

Pantalla de login con altísima fidelidad visual. Las desviaciones son micro-detalles que no comprometen la experiencia, salvo el tamaño táctil del link de contraseña olvidada (única observación de **severidad Media**).

**Acción recomendada:** corregir el hitSlop del link `¿Olvidaste tu contraseña?` antes del merge. El resto puede abordarse como deuda técnica de baja prioridad.
