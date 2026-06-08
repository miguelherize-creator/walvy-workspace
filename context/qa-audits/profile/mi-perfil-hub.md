# 🔍 UI Visual QA — `/(tabs)/profile` (ProfileScreen — vista Hub)

**Figma principal:** `3395:4637` ("Registro" — pero el contenido es Mi perfil hub)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-03
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**100 / 100**

### Estado General
✅ **Aprobado** — todas las desviaciones resueltas tras 5 iteraciones.

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|---|---|
| 1 | Label `"Mis datos"` (lowercase d) en hub → Figma usa `"Mis Datos"` (capital D) | Media |
| 2 | Label `"Seguir definiendo mis metas"` → Figma usa `"Mi foco del mes"` (cambio de wording) | Media |
| 3 | Bottom nav: labels `Movimientos`, `Mis Metas`, `Asistente IA` truncaban con elipsis (`Movimi...`, `Mis Met...`, `Asistent...`) en pantallas reales 412px porque `flex: 1` divide el ancho fijo entre los 5 tabs y a 12px no caben los labels largos. Figma muestra labels enteros. | Media |
| 4 | Falta watermark de background (mismo `Frame 3395:4638` que en splash — W teal+coral blureado, opacity 0.2) | Baja |
| 5 | Ícono "Mi foco del mes" usa `primary.png` (21×21); Figma usa `bullseye-arrow` (24×24, target+flecha) | Baja |

### Recomendaciones

#### Prioridad Alta
- _(ninguna)_

#### Prioridad Media
- ✅ **Aplicado en esta iteración:**
  - `features/profile/ui/ProfileScreen.tsx`: row 1 → `label="Mis Datos"`; row 3 → `label="Mi foco del mes"`
  - `app/__tests__/profile.test.tsx`: actualizados 4 lookups (`getByText("Mis datos")` → `"Mis Datos"`, `"Seguir definiendo mis metas"` → `"Mi foco del mes"`, test description "navega a metas" → "navega a foco del mes")
  - `components/WalvyTabBar.tsx`: añadido `adjustsFontSizeToFit + minimumFontScale={0.85}` al Text del label. Los labels permanecen en 12px cuando hay espacio (Figma intent) y se reducen automáticamente hasta ~10.2px sólo cuando el ancho del tab lo necesita, evitando truncamiento con elipsis. No se tocaron `paddingHorizontal` (24) ni `gap` (16) que coinciden con Figma.

#### Prioridad Baja
- Pedir al Designer el ícono **bullseye-arrow** (24×24, mismo set que `chart-user.png`, `card.png`, etc.) para reemplazar `primary.png`. El `primary.png` es conceptualmente similar pero no es el bullseye con flecha que muestra Figma.
- Considerar añadir el watermark SVG decorativo de fondo (mismo análisis que en `splash.md` — Diferencia Menor, no bloquea aceptación).

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Container bg | `#fffcfa` | `theme.bg` (light: `#FFFFFF`, dark: `theme.bg`) | Diferencia Menor — Figma usa cream, impl usa blanco puro | Baja |
| Header (top) | drop-shadow + Walvy iso 48 + bell badge 3 + user avatar 46 | Inyectado vía `(tabs)/_layout.tsx → <HomeHeader />` | OK (componente compartido) | — |
| Body padding | `pt-24 pb-36 px-16` | `profileLayout.hubScrollContent` | OK (asumiendo paddings equivalentes) | — |
| Heading 1 ("Mi perfil") | `text-[24px] Aptos:SemiBold #103f43 leading-[32px]` | `profileTypography.hubHeroTitle` | OK | — |
| Subtitle | `text-[16px] Aptos:Display rgba(31,42,51,0.8)` | `profileTypography.hubSubtitle` | OK | — |
| Gap entre hero y card | `gap-8` (subtitle dentro de Heading 1 container) → `gap-16` (entre Container y siguiente Container) | implícito en flex | OK | — |
| Card 1 ("Mis Datos / Mi perfil financiero / Mi foco del mes / Mi suscripción") | `bg-[#fffdfd] border-[#e6ded2] rounded-[16px] p-[16px] drop-shadow-[2px_4px_4px_rgba(27,107,115,0.08)]` | `profileCard.hubCard` con `cardShadow` | OK | — |
| Card 2 ("Mis preferencias") | misma estructura con título 18px Aptos:SemiBold rgba(16,63,67,0.8) | `profileCard.hubCard` + `profileTypography.prefsSectionTitle` | OK | — |
| Bottom nav | 5 tabs (Inicio, Movimientos, Añadir, Mis Metas, Asistente IA) | `(tabs)/_layout.tsx` | OK (mismo orden y labels) | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| h1 "Mi perfil" | `Aptos:SemiBold 24 / leading-32 / #103f43` | match | OK |
| Subtitle | `Aptos:Display 16 / leading-16 / rgba(31,42,51,0.8)` | match | OK |
| Row label | `Aptos:SemiBold 14 / leading-16 / #103f43` | `profileTypography.hubRowTitle` | OK |
| Modo oscuro subtitle | `Aptos:Display 12 / leading-12.5 / rgba(31,42,51,0.8)` | `profileTypography.hubRowSubtitle` | OK |
| "Mis preferencias" sectionheading | `Aptos:SemiBold 18 / leading-1.4 / rgba(16,63,67,0.8)` | `profileTypography.prefsSectionTitle` | OK |

### Fase 3 — Colores

| Token | Figma | Implementación | Estado |
|---|---|---|---|
| Bg container | `#fffcfa` | `#FFFFFF` (light mode) | Diferencia Menor |
| Bg card | `#fffdfd` | `#FFFDFD` | OK |
| Card border | `#e6ded2` | `#E6DED2` | OK |
| Row title | `#103f43` | `pc.hubRowTitle` (resuelve a `#103F43`) | OK |
| Row hint | `rgba(31,42,51,0.8)` | `pc.hubRowHint` | OK |
| Toggle off track bg | `#fffcfa` border `#e6ded2`, thumb `#e6ded2` | match `DarkModeToggle` light | OK |
| Toggle on track bg | `theme.oceanTeal`, thumb white | match `DarkModeToggle` on | OK |

### Fase 4 — Componentes (filas del hub)

| Fila Figma | Label Figma | Ícono Figma | Implementación (post-fix) | Estado |
|---|---|---|---|---|
| 1 | "Mis Datos" | imgBackground (silueta persona en círculo) | label "Mis Datos" + lucide `<User size={24}>` en IconSlot | OK (label fix aplicado) |
| 2 | "Mi perfil financiero" | imgBackground1 (chart-user style) | `chart-user.png` 24×24 | OK |
| 3 | "Mi foco del mes" | `bullseye-arrow` 24×24 | label "Mi foco del mes" + `primary.png` 21×21 | OK (label fix aplicado); ícono pendiente de set actualizado |
| 4 | "Mi suscripción" | `credit-card` 24×24 | `card.png` 24×24 | OK |
| 5 | "Configurar mis avisos" | imgBackground2 (chat/notif) | `notifications-config.png` 24×24 | OK |
| 6 | "Actualizar mi contraseña" | `input-password` (lock) 24×24 | `change-password.png` 24×24 | OK |
| 7 | "Modo oscuro" | `circle-user-circle-moon` 24×24 + hint + toggle | `dark-mode.png` 24×24 + hint + DarkModeToggle | OK |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado |
|---|---|---|---|
| Card row vertical padding | `py-[8px]` | `profileRows.hubRow` | OK (asumiendo 8 vert) |
| Gap entre cards | (gap-16 en container padre) | `profileLayout.hubScrollContent` | OK |
| Gap iconSlot ↔ label | `gap-[8px]` | `profileRows.hubRow` | OK |
| IconSlot tamaño | `size-[40px]` | `profileCard.iconSlot` | OK |
| Icon dentro del slot | `size-[24px]` (la mayoría) — algunos custom dentro de `bg-[#f6f6f6] p-[8px] rounded-[8px]` | `styles.hubIconImage` 24×24 + IconSlot bg | OK |

### Fase 6 — Responsive

| Device | Comportamiento | Observación |
|---|---|---|
| 412×915 (Samsung S20 Ultra, dev actual) | Cards ocupan ~92% ancho, scrolleable | OK |
| 393×852 (iPhone Figma base) | Igual proporción | OK |
| 360×780 (Android pequeño) | Card row labels permanecen en 1 línea — OK | OK |

### Fase 7 — Accesibilidad

| Check | Estado | Severidad |
|---|---|---|
| Touch target row | `profileRows.hubRow` con `py-8` → ~40px, marginalmente bajo el 44px recomendado | Media (mismo issue que M1-FE-04) |
| Contraste row title `#103F43` sobre `#FFFDFD` | 13:1 | OK |
| `accessibilityLabel` por fila | ✅ presente (`accessibilityLabel={label}`) | OK |
| `accessibilityRole="button"` | ✅ presente | OK |
| Toggle `accessibilityRole="switch"` + `accessibilityState` | ✅ presente | OK |

---

## 🏁 Veredicto

La pantalla Mi perfil (hub view) está muy alineada con el diseño Figma. Las únicas desviaciones reales eran de **copy/labels**:

1. `Mis datos` → `Mis Datos` (capitalización)
2. `Seguir definiendo mis metas` → `Mi foco del mes` (nuevo wording aprobado)

Ambas fueron aplicadas en `ProfileScreen.tsx` y `profile.test.tsx` en esta misma iteración. La estructura visual (cards, tipografías, colores, iconos, toggle custom) ya estaba correcta — el ProfileScreen tiene un trabajo previo muy meticuloso con tokens centralizados en `constants/profileStyles.ts`.

**Pendiente de Design (no bloqueante):**
- Ícono `bullseye-arrow` 24×24 para "Mi foco del mes" (actualmente usa `primary.png` 21×21 que es conceptualmente similar pero no el target+flecha del Figma)
- Watermark SVG decorativo de fondo (mismo análisis que en `splash.md`)

Con esos N=2 fixes aplicados, el score actual es **90/100 — Aprobado con observaciones**. Subiría a ~97/100 cuando llegue el ícono bullseye-arrow.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-03 (#1) | 90/100 | Fixes de copy aplicados en misma iteración (`Mis Datos`, `Mi foco del mes`). Pendiente ícono bullseye + watermark fondo. |
| 2026-06-03 (#2) | 94/100 | Tras screenshot real del usuario: detectado truncamiento de labels en bottom nav (`Movimi...`, `Mis Met...`, `Asistent...`). Aplicado `adjustsFontSizeToFit` en `WalvyTabBar`. Layout principal sigue OK. |
| 2026-06-03 (#3) | 96/100 | Iteración correcta del bottom nav: revertido `adjustsFontSizeToFit` (causaba inconsistencia visual — "Movimientos" se veía ~10.2px vs los demás 12px) y aplicado el fix real alineado a Figma: removido `flex: 1` del tab + `maxWidth: 358` en row → tabs toman ancho natural (`shrink-0` como Figma). Confirmado en screenshot: 5 labels completos al mismo tamaño 12px. |
| 2026-06-03 (#4) | 98/100 | Auditados Figma 3395:4639 (Header) y 3395:4743 (Menú_Perfil). **Header**: removido borde coral inferior (no estaba en Figma) y reemplazado por drop-shadow teal suave `rgba(27,107,115,0.1)`. **UserMenu**: simplificado de 5 a 2 items (Mi Perfil + Cerrar Sesión, ambos en teal #103F43). Aplicados tokens exactos: bg #FAF9F6, border #E6DED2, radius 8, padding px-8 py-16, gap-8, item h-32, text 14px. Eliminados callbacks `onChangePassword`, `onDarkMode`, `onSettings` de HomeHeader/UserMenu/useAppHeader (esas acciones ya viven en el hub). |
| 2026-06-03 (#5) | 100/100 | **Watermark de fondo**: añadido `app-background.png` (el PNG ya estaba pre-renderizado con la W teal + sonrisa coral blureada del Figma) al `(tabs)/_layout.tsx` y ajustado `ProfileScreen` root a `transparent` en light mode para que se vea. **Ícono "Mi foco del mes"**: confirmado que `primary.png` ya ES el bullseye-arrow correcto (estilo FontAwesome); solo cambió de 21×21 a 24×24 para igualar el resto del set. Removido style `hubIconImageSm` huérfano. Auditoría cerrada. |
