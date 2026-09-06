# 🔍 UI Visual QA — `/(tabs)/debt-route` (DebtRouteScreen · estado vacío)

**Figma principal:** `10145:24232`
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-09-05
**Auditor:** UI Visual QA Reviewer
**Componente:** `features/debts/ui/components/DebtEmptyState.tsx` (vía `DebtRouteScreen.tsx:145-161`)

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**78 / 100** → **92 / 100** con los tres fixes de código aplicados

### Estado General
⚠️ **Aprobado con observaciones** — la estructura es correcta, queda un defecto de asset fuera del código.

### Principales Problemas (priorizados)

| # | Problema | Severidad | Estado |
|---|---|---|---|
| 1 | Sin `ScrollView`: el contenido mide 605dp y el viewport real es 605dp — en cualquier pantalla más chica se recortaba sin scroll | Alta | ✅ Corregido |
| 2 | Mascota servida a 105×80 en CDN para un slot de 160×160 | Alta | ⛔ Pendiente (asset, no código) |
| 3 | `cardBodyMd` con `lineHeight: 16` sobre 14px (1.14×) — descendentes encimados | Media | ✅ Corregido → 21 |
| 4 | `info.png` 21×21 estirado a la caja de 24 del diseño | Baja | ✅ Corregido → `CircleInfoIcon` (SVG) |

### Recomendaciones

#### Prioridad Alta
- **Republicar las tres mascotas del semáforo en el CDN a ≥480×480.** `Walvly_short_search.png`, `walVy_short_ok.png` y `Walvy_short_money.png` están las tres a 105×80 (el resto del catálogo va de 264 a 291). La fuente en Figma es de 941×1676, así que el original existe. Reemplazando el objeto en la misma ruta de S3 no hay que tocar código.

#### Prioridad Media
- Migrar los otros cuatro usos de `info.png` a `CircleInfoIcon` (`DebtReviewScreen`, `DebtAnalyzingScreen`, `ForgotPasswordScreen`, `OnboardingAnalyzingScreen`) cuando se audite cada pantalla.

#### Prioridad Baja
- `DebtEmptyState.hintText` duplica `debtTypography.overlayBody` añadiéndole `lineHeight: 21`. Consolidar cuando se audite `DebtUploadScreen`, que es el otro consumidor del token.
- `debtTypography.cardBodySm` (12/16 = 1.33×) queda apenas bajo el mínimo de Manrope (1.366×). No se usa en esta pantalla; revisar al auditar la card de documentos.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

Medido contra la geometría exacta del frame (`get_metadata`), replicando los estilos RN a 393dp con los TTF de Manrope que embarca la app.

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contenedor | `pt-24 / pb-36 / px-16` | `paddingTop 24 · paddingBottom 36 · paddingHorizontal 16` | OK | — |
| Columna | `flex-1 justify-between` | `flex:1 · justifyContent:"space-between"` | OK | — |
| Heading → card | gap 16 | `top.gap = spacing.lg` | OK | — |
| Card | 361×387 · p16 · gap24 · r16 | 361×**408** · p16 · gap24 · r16 | Diferencia Menor | Baja |
| Card · mascota → texto | 24 | 24 | OK | — |
| Card · texto → acciones | 24 | 24 | OK | — |
| Acciones (gap interno) | 16 | 16 | OK | — |
| Bloque de texto | 52 | **70** | Diferencia Menor | Baja |
| Overlay | 361×66 · p16 · gap8 · r16 | 361×**74** | Diferencia Menor | Baja |
| Aire card ↔ overlay | 114 | **0** en el teléfono | Diferencia Media | Media |
| Desbordamiento | — | sin `ScrollView`: se recortaba | **Diferencia Crítica** | **Alta** |

**Sobre las diferencias de altura:** salen del mismo origen y no son corregibles en RN. Figma compone con `text-box-trim` (recorta la caja del texto a la altura de mayúscula) y con Aptos; RN no tiene trim y la app usa Manrope, más ancha. El cuerpo pasa de 2 a 3 líneas, así que bloque de texto 52→85, card 387→423 y overlay 66→74. La migración Aptos→Manrope ya está registrada como no-divergencia.

**Sobre el aire — no es una medida del diseño.** El frame reparte con `justify-between`: ese hueco es `viewport − contenido`, no un espaciador. El presupuesto de altura explica por qué en el teléfono desaparece:

| | Figma | app real |
|---|---|---|
| Barra de estado | 0 — el frame arranca en `y=80` y no la modela | ~28 |
| `HomeHeader` | 80 | 80 (`16 + 48 + 16`) |
| **Viewport de la pantalla** | **675** | **605** |
| Tab bar | 98 | 140 (`1 + 17 + 74 + 48` con los 3 botones de Android) |
| Total | 853 | 853 |

El contenido mide `24 + 32 + 16 + 423 + 74 + 36 = **605**`. Con 605 de viewport el aire da exactamente **0**, que es lo que se ve en el dispositivo: card y overlay pegados. En cualquier pantalla más corta —o con la fuente del sistema ampliada— el contenido se pasaba y quedaba **recortado sin posibilidad de scroll**, dejando «Continuar más tarde» fuera de alcance. En un viewport de 520dp faltan 85.

**Fix aplicado:** `DebtEmptyState` pasa a `ScrollView` con `contentContainerStyle={{ flexGrow: 1 }}` y la columna con `flexGrow: 1` + `justify-between`. Mantiene el reparto del diseño mientras haya espacio y permite desplazar cuando no lo hay — el mismo patrón que ya usan `DebtAnalyzingScreen` y ocho pantallas de auth.

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Título de pantalla | Aptos SemiBold 24/32 | `fontFamily.semiBold` 24/32 | OK | — |
| Título de card | Aptos SemiBold 16 / normal | `fontFamily.semiBold` 16, sin lineHeight | OK | — |
| Cuerpo de card | Aptos:Display 14/**16** | `fontFamily.regular` 14/**16** → **21** | Diferencia Media | Media |
| Botón primario | Aptos SemiBold 16 | `fontFamily.semiBold` 16 | OK | — |
| Botón terciario | Aptos SemiBold 16 + underline | ídem + `textDecorationLine` | OK | — |
| Texto del overlay | Aptos Regular 14 / normal | `fontFamily.regular` 14/21 | OK | — |

**Cuerpo de card:** los 16 de interlínea del Figma cuentan con el recorte de `text-box-trim`. Aplicados literales sobre Manrope dan 1.14× del tamaño de fuente, por debajo del 1.366× que exigen sus métricas (hhea 2132+600 sobre UPM 2000) — los descendentes de «agrega», «y», «Despeje» chocan con la línea siguiente. Se sube a 21 (1.5×), el mismo valor que ya usaba el overlay.

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Título de pantalla | `#103F43` | `theme.deepTeal` | OK |
| Card bg / borde | `#FFFDFD` / `#E6DED2` | `FIGMA_CARD_BG_LIGHT` / `FIGMA_CARD_BORDER` | OK |
| Sombra de card | `2px 4px 4px rgba(27,107,115,0.08)` | `debtCardShadow` | OK |
| Círculo de la mascota | `#F8F4ED` | `FIGMA_MASCOT_CIRCLE` | OK |
| Cuerpo de card | `rgba(31,42,51,0.8)` | `theme.authMutedText` | OK |
| Botón primario | bg `#1B6B73` · texto `#FFFCFA` | `theme.oceanTeal` · `theme.authBg` | OK |
| Botón terciario | `#177E96` | `theme.authLinkText` | OK |
| Overlay bg | `rgba(27,107,115,0.05)` | `FIGMA_OVERLAY_BG_LIGHT` | OK |
| Overlay texto + ícono | `#1B6B73` | `theme.oceanTeal` | OK |

Los nueve tokens de color coinciden exactamente. Nada hardcodeado en el componente.

### Fase 4 — Componentes

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Botón primario | h-39/40 · r-100 · w-full | `height 40` · `borderRadius.full` · `width "100%"` | OK | — |
| Botón terciario | h-40 · r-100 · w-full | `height 40` · ídem | OK | — |
| Círculo de mascota | 160×160 | 160×160 | OK | — |
| **Imagen de la mascota** | recorte de un PNG de 941×1676 llenando el círculo | PNG de **105×80** con `resizeMode="contain"` | **Diferencia Crítica** | **Alta** |
| Ícono del overlay | SVG 24×24 | `info.png` **21×21** → `CircleInfoIcon` 24×24 | Diferencia Menor | Baja |

**Mascota:** `MEDIA.mascots.semaforoAmarillo` resuelve a `/mascots/Walvly_short_search.png`, que el CDN sirve a 105×80 (verificado con `curl`: 200, `x-cache: Hit`). En un slot de 160 eso es un escalado de 1.52× en puntos — 3.05× en píxeles reales sobre un dispositivo de densidad 2, 4.6× en uno de densidad 3. Además, al ser apaisado (1.31) dentro de un círculo cuadrado, `contain` lo deja en 160×122 y no llena el círculo como sí hace la máscara del Figma. Las otras dos mascotas del semáforo tienen el mismo problema; el resto del catálogo está entre 264 y 291 px.

Se deja `contain` a propósito: pasar a `cover` con este asset apaisado recortaría al personaje por los costados. El fix correcto es republicar el PNG.

### Fase 7 — Accesibilidad

| Elemento | Criterio | Resultado | Estado |
|---|---|---|---|
| Cuerpo sobre card | contraste | `rgba(31,42,51,0.8)` sobre `#FFFDFD` ≈ 9.7:1 | OK |
| Texto del overlay | contraste | `#1B6B73` sobre el overlay ≈ 5.3:1 | OK |
| Botón primario | contraste | `#FFFCFA` sobre `#1B6B73` ≈ 5.6:1 | OK |
| Botones | target táctil | 40dp de alto (Figma pide 39/40) | Diferencia Menor | 
| `DebtButton` | rol y label | `accessibilityRole="button"` + `accessibilityLabel` | OK |

Los 40dp de alto quedan bajo los 44 recomendados, pero es el valor del diseño: la skill prohíbe reinterpretar. Corresponde `hitSlop`, ya registrado como deuda (M1-FE-04 / M2-FE-02).

---

## 🏁 Veredicto

La pantalla está bien construida: la estructura del frame se respeta punto por punto —columna `justify-between` con el overlay anclado abajo, card de 16 de padding y 24 de gap, los tres bloques internos en su orden y separación— y los nueve tokens de color calzan exactamente con el Figma, sin un solo hex suelto en el componente. Los desajustes de altura (card 387→423, overlay 66→74) son consecuencia mecánica de que RN no tiene `text-box-trim` y de que Manrope es más ancha que Aptos: no son corregibles sin desviarse del diseño en otra dimensión.

El hallazgo de fondo lo destapó el aire perdido entre la card y el overlay. Ese hueco no es una medida del diseño sino el sobrante del `justify-between`, y el presupuesto de altura muestra que el contenido pasó a medir exactamente lo mismo que el viewport real (605dp): la pantalla estaba al borde del desbordamiento y, sin `ScrollView`, cualquier dispositivo más corto perdía el enlace «Continuar más tarde» sin manera de alcanzarlo. Es el defecto más grave de la auditoría y el que menos se ve en una captura de un teléfono grande.

Los otros dos defectos de código también están corregidos. El de la interlínea era el visible: a 1.14× las tres líneas del cuerpo se leían apretadas y los descendentes tocaban la línea de abajo — el mismo defecto que se corrigió en `profileTypography.subtitle` en el PR #117, y por la misma causa.

Queda un pendiente que no se resuelve en el repositorio: la mascota. Es el problema de mayor severidad de la pantalla y su arreglo es republicar el objeto en S3 en la misma ruta, sin tocar código. Mientras siga a 105×80 el score no puede pasar de ~92.

Con la mascota republicada a ≥480×480, el score sube a ~98/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-09-05 (#1) | 78/100 → 92/100 | Sin scroll con contenido al límite del viewport, interlínea del cuerpo e ícono PNG — corregidos; mascota a 105×80 pendiente en CDN |
