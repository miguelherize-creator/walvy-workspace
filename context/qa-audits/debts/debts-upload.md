# 🔍 UI Visual QA — `/(tabs)/debts-upload` (DebtUploadScreen · estado inicial)

**Figma principal:** `5897:11664`
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-09-05
**Auditor:** UI Visual QA Reviewer
**Componente:** `features/debts/ui/DebtUploadScreen.tsx`

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**84 / 100** → **94 / 100** con los fixes aplicados

### Estado General
⚠️ **Aprobado con observaciones** — la estructura calca el frame; los hallazgos son de assets e interlínea.

### Principales Problemas (priorizados)

| # | Problema | Severidad | Estado |
|---|---|---|---|
| 1 | Chevron de volver un 46% más grande que el diseño (PNG recortado estirado a la caja de 32) | Alta | ✅ Corregido → `ChevronLeftIcon` |
| 2 | `stepCounter` con `lineHeight` igual al tamaño de fuente (1.0×, 5.9px bajo el piso de Manrope) | Media | ✅ Corregido → 22 |
| 3 | `cardBodySm` a 1.33×, visiblemente más apretado que el `cardBodyMd` de la card de al lado | Media | ✅ Corregido → 18 |
| 4 | `shield-check.png` raster de 24×24 donde el diseño tiene un SVG | Baja | ✅ Corregido → `ShieldCheckIcon` |

### Recomendaciones

#### Prioridad Media
- Migrar el chevron de volver en las otras **ocho** pantallas de M04. Todas usan `chevrons2.png` a `12×18`, que reproduce el glifo con un tamaño aproximadamente correcto pero pierde la caja de 32 del diseño — y con ella el área táctil.
- `shield-check.png` sigue en `DebtReviewScreen`.

#### Prioridad Baja
- `screenTitle` (24/32 = 1.333×) y los labels del stepper (12/16 = 1.333×) quedan 0.8px y 0.4px bajo el piso de Manrope. Se dejan como están: son los valores del Figma y el título ya se validó en dispositivo en la pantalla 0.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

Medido contra la geometría del frame (`get_metadata`) replicando los estilos RN a 393dp con los TTF de Manrope de la app.

| Bloque | Figma | Antes | Después | Estado |
|---|---|---|---|---|
| Contenedor | `pt24 / pb36 / px16`, columna gap-16 | `debtLayout.scrollContent` | = | OK |
| Header (título + paso) | 56 | 56 | 62 | Diferencia Menor |
| Stepper | 42 | 42 | 42 | OK |
| Section title | 32 | 32 | 32 | OK |
| Card 1 | 197 | 203 | 209 | Diferencia Menor |
| Card 2 | 147 | 163 | 163 | Diferencia Menor |
| Overlay | 113 | 121 | 121 | Diferencia Menor |
| CTA «Siguiente» | 40 | 40 | 40 | OK |
| **Inner total** | **723** | **753** | **765** | — |

Los siete bloques están en su orden y con el gap-16 correcto; las cards respetan `p16 / gap24 / r16` y sus bloques internos el `gap8` (card 1) y el `gap0` (card 2) que marca el diseño. El crecimiento es el de siempre: sin `text-box-trim` y con Manrope más ancha que Aptos, cada bloque de texto ocupa más.

Con 765 de inner la pantalla necesita **825dp**, muy por encima de los ~605 de viewport real — pero ya está dentro de un `ScrollView`, así que no hay recorte.

### Fase 2 — Tipografía

Piso de interlínea de Manrope = **1.366×** (hhea `2132 / -600`, UPM 2000, leído del TTF que embarca la app; OS/2 typo y win coinciden).

| Token | Tamaño/lh | Ratio | Mínimo | Veredicto |
|---|---|---|---|---|
| `screenTitle` | 24/32 | 1.333 | 32.8 | 0.8px corto — se deja |
| `stepCounter` | 16/**16** | **1.000** | 21.9 | **5.9px corto** → **22** |
| `sectionTitle` | 18/32 | 1.778 | 24.6 | OK |
| `cardTitle` | 16 / natural | — | — | OK |
| `cardBodySm` | 12/**16** | 1.333 | 16.4 | 0.4px corto → **18** |
| `cardBodyMd` | 14/21 | 1.500 | 19.1 | OK |
| `hint` | 12/18 | 1.500 | 16.4 | OK |
| `stepLabel` (×2) | 12/16 | 1.333 | 16.4 | 0.4px corto — se deja |

`stepCounter` es el caso claro: interlínea igual al tamaño de fuente no deja sitio para ningún descendente. `cardBodySm` está apenas bajo el piso, pero es copy de varias líneas y quedaba visiblemente más apretado que el `cardBodyMd` de la card inmediatamente debajo — sube a 18 para igualar a `hint`, que es el otro token de 12px.

Los dos que se dejan están 0.4 y 0.8px cortos, son los valores literales del Figma y no muestran recorte en dispositivo.

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Título / section title | `#103F43` | `theme.deepTeal` | OK |
| «Paso 1 de 3» y cuerpos | `rgba(31,42,51,0.8)` | `theme.authMutedText` | OK |
| Barra del stepper | `#EF9682` | `FIGMA_STEPPER_CORAL` | OK |
| Label del paso siguiente | `rgba(31,42,51,0.4)` | `FIGMA_STEP_LABEL_NEXT_LIGHT` | OK |
| Card bg / borde | `#FFFDFD` / `#E6DED2` | `FIGMA_CARD_BG_LIGHT` / `FIGMA_CARD_BORDER` | OK |
| Sombra de card | `2px 4px 4px rgba(27,107,115,0.08)` | `debtCardShadow` | OK |
| Botón secundario | borde y texto `#1B6B73` | `theme.oceanTeal` | OK |
| Overlay bg | `rgba(27,107,115,0.05)` | `FIGMA_OVERLAY_BG_LIGHT` | OK |
| Overlay título / cuerpo | `#103F43` / `#1B6B73` | `dc.overlayTitle` / `dc.overlayBody` | OK |
| CTA deshabilitado | `rgba(27,107,115,0.3)` sobre `#FFFCFA` | `FIGMA_CTA_DISABLED` / `theme.authBg` | OK |
| Chevron | `#005259` | `dc.backChevron` | OK |

Todos los colores salen de tokens; no hay un solo hex suelto en la pantalla.

### Fase 4 — Componentes

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| **Chevron de volver** | SVG, glifo 12.2×22.5 en caja de 32 | `chevrons2.png` **13×23** estirado a 32×32 → glifo **18.1×32** | **Diferencia Crítica** | **Alta** |
| Ícono del overlay | SVG 24×24 | `shield-check.png` 24×24 raster | Diferencia Menor | Baja |
| Stepper | `p8`, `gap2`, barra `h8` r-100, Present relleno / Next borde 1px | `DebtStepper` idéntico | OK | — |
| Botón secundario | h-39, r-100, hug centrado | `DebtButton variant="secundario"` + `hugRow` | OK | — |
| CTA primario | h-40, w-full, disabled | `DebtButton variant="primario"` | OK | — |

**Chevron:** `chevrons2.png` es el glifo recortado a su bounding box. Renderizado en una caja de 32 con `contain` da 18.1×32, un **46% más grande** que los 12.2×22.5 del diseño. Las otras ocho pantallas de M04 lo dibujan a `12×18`, que se acerca al tamaño correcto — esta era la única con 32. Con `ChevronLeftIcon` el viewBox es la caja de 32 completa, así que el glifo recupera su tamaño y la caja mantiene los 32pt de área táctil.

### Fase 7 — Accesibilidad

| Elemento | Criterio | Resultado | Estado |
|---|---|---|---|
| Botón volver | área táctil | 32pt + `hitSlop={8}` = 48 | OK |
| Botones de card | alto | 39pt (valor del diseño) | Diferencia Menor |
| CTA | alto | 40pt (valor del diseño) | Diferencia Menor |
| Stepper | rol | `accessibilityRole="progressbar"` | OK |
| Botón volver | label | `accessibilityLabel="Volver"` | OK |
| Cuerpos de card | contraste | `rgba(31,42,51,0.8)` sobre `#FFFDFD` ≈ 9.7:1 | OK |
| Label del paso siguiente | contraste | `rgba(31,42,51,0.4)` ≈ 3.2:1 | Diferencia Menor |

El label del paso siguiente queda bajo 4.5:1, pero es texto deliberadamente atenuado que marca un paso aún no alcanzado y su información está duplicada en la barra. Es el valor del Figma.

---

## 🏁 Veredicto

La pantalla estaba mejor construida que la 0 en lo estructural: los siete bloques del frame están en su orden con el gap-16 correcto, las cards respetan padding, gap y radio, el stepper es una réplica exacta del componente de Figma —incluido el `gap: 2` y el `padding: 8` que casi nadie copia— y los once colores salen de tokens sin un hex suelto. También ya venía con `ScrollView`, así que el problema de recorte de la pantalla 0 no se repite aquí pese a necesitar 825dp.

El hallazgo de peso es el chevron de volver: un PNG recortado al glifo y estirado a una caja de 32, un 46% más grande de lo diseñado. Es el mismo patrón que apareció en los íconos de la tab bar y en `info.png` — el asset se recorta al bounding box y se pierde el padding interno que forma parte del ícono. Vale notar que las otras ocho pantallas del módulo no tienen este problema: dibujan el mismo PNG a `12×18`, cerca del tamaño real. Esta era la excepción.

En tipografía, `stepCounter` con interlínea igual al tamaño de fuente es el único caso inequívoco. Los otros dos que quedan bajo el piso lo están por menos de un píxel, son los valores literales del Figma, y el título ya se validó en dispositivo en la pantalla anterior: corregirlos sería reinterpretar el diseño sin evidencia de que haga falta.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-09-05 (#1) | 84/100 → 94/100 | Chevron 46% oversized e interlíneas bajo el piso de Manrope — corregidos; quedan 8 pantallas con el mismo chevron |
