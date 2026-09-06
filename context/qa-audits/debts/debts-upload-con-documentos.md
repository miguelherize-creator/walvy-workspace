# 🔍 UI Visual QA — `/(tabs)/debts-upload` (DebtUploadScreen · con documentos y error de contraseña)

**Figma principal:** `5897:12030` (card «Carga tus documentos» con 3 documentos)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-09-05
**Componentes:** `features/debts/ui/DebtUploadScreen.tsx` · `components/StatementDocRow.tsx`

Complementa a [`debts-upload.md`](debts-upload.md), que audita el estado inicial de la misma pantalla.

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**89 / 100** → **95 / 100** con el fix aplicado

### Principales Problemas

| # | Problema | Severidad | Estado |
|---|---|---|---|
| 1 | Contador «3/15» heredaba SemiBold 16 del título y quedaba pegado a él | Media | ✅ Corregido |
| 2 | Chevron de colapsar que el Figma no dibuja en ningún estado | Media | ⚠️ Decisión de producto — no se toca |
| 3 | Altura del botón terciario: 40 en código, 24 en este frame, 40 en el de la pantalla 0 | Baja | ⚠️ Inconsistencia del propio diseño |
| 4 | `StatementDocRow.label` / `inputError` a 12/16 (0.4px bajo el piso de Manrope) | Baja | ⚠️ Compartido con M01 |

---

## 📋 Detalle

### Fase 1 — Layout de la card con documentos

Geometría exacta del frame (`get_metadata`), card 361×434:

| Elemento | Figma | Implementación | Estado |
|---|---|---|---|
| Encabezado → lista | gap 8 | `cardTextBlock` gap 8 | OK |
| Fila de documento | 32 de alto | `StatementDocRow.row` | OK |
| Ícono de estado → contenido | 16 (ícono en x=0, contenido en x=32) | `row.gap = spacing.lg` | OK |
| Ícono de archivo → nombre | 4 (ícono x=0, texto x=20) | `nameRow.gap = spacing.xs` | OK |
| Tamaño → estado | 8 (33px + 8) | `metaRow.gap = spacing.sm` | OK |
| Contenido → papelera | 16 | `row.gap` | OK |
| Fila → divisor | 8 arriba y 8 abajo | `list.gap` + divisor por fila | OK |
| Divisor tras el último documento | sí (`Vector 34`) | sí | OK |
| Fila → bloque de contraseña | 8 | `root.gap = spacing.sm` | OK |
| Lista → acciones | 24 | `debtLayout.card` gap 24 | OK |
| Botón → hint | 8 | `cardActionBlock` gap 8 | OK |

La geometría de las filas calca el frame punto por punto. Único detalle del propio Figma: en la fila con contraseña el contenido arranca en x=24 en vez de x=32 — 8px de diferencia contra las otras dos filas, que parece descuido del archivo y no una intención.

### Fase 2 — Encabezado de la card

| Propiedad | Figma (`5897:12032`) | Antes | Después |
|---|---|---|---|
| Fila | `flex gap-16 items-center` | `justifyContent: "space-between"` | `gap: 16` |
| Título | `flex-1`, SemiBold 16, `#103f43` | sin `flex` | `flex: 1` |
| Contador | hermano, `shrink-0`, **Regular 12**, `rgba(76,85,92,0.8)` | `<Text>` anidado → heredaba **SemiBold 16** | token `dc.docCounter` |

El contador estaba dentro del `<Text>` del título, así que solo el color cambiaba: se renderizaba a 16px SemiBold y pegado al texto («Carga tus documentos 3/15») en vez de pequeño y alineado a la derecha. El color del Figma, `rgba(76,85,92,0.8)`, es el `FIGMA_DOC_NAME_LIGHT` (`#4C555C`) al 80%.

### Fase 4 — Elementos extra o divergentes

| Elemento | Figma | Implementación | Veredicto |
|---|---|---|---|
| **Chevron de colapsar** | **No existe** en ninguno de los cinco frames del flujo, ni con documentos ni sin ellos | La app lo muestra cuando hay contenido | **Elemento extra** |
| Banner «queda fuera de este análisis» | No existe | La app lo muestra | Hueco del diseño, ver abajo |
| Botón «Cargar más documentos» | terciario **191×24** | `DebtButton` terciario, 40 | Inconsistencia entre frames |

**Chevron:** el comentario de `CardHeader` dice que «el Figma no dibuja chevron: las cards son estáticas mientras están vacías. Aparece solo cuando hay contenido que colapsar». Eso no se sostiene: `5897:12030` tiene tres documentos cargados y tampoco lo dibuja. Colapsar la lista es una decisión de producto razonable, pero hoy está justificada con una lectura del diseño que no es cierta. Requiere ADR o quitarse.

**Altura del terciario:** el diseño se contradice consigo mismo — 24 en este frame, 40 en el `10145:24232` de la pantalla 0. La implementación usa 40 para los dos. No se toca sin que diseño defina cuál vale.

### Fase 2 — Tipografía de `StatementDocRow`

| Token | Tamaño/lh | Ratio | Mínimo | Veredicto |
|---|---|---|---|---|
| `name` | 14/21 | 1.500 | 19.1 | OK |
| `meta` / `metaStrong` | 12/18 | 1.500 | 16.4 | OK |
| `label` | 12/16 | 1.333 | 16.4 | 0.4px corto |
| `inputError` | 12/16 | 1.333 | 16.4 | 0.4px corto |

Los dos últimos se dejan: el componente lo comparte el onboarding de M01 y tocarlo excede una auditoría de M04.

---

## 📌 Las tres notas «Para desarrollo» del flujo

Notas del diseñador en el canvas, contrastadas contra la implementación actual.

### Nota 1 — Estados intermedios de procesamiento

> «Falta representar los estados intermedios: subiendo, procesando, leído/no leído, no procesable o error técnico.»

**Parcialmente implementado.** `StatementDocStatus` cubre `idle · checking · needsPassword · verifying · invalidPassword · verified`. Faltan «Subiendo documento», «Procesando documento» y «No pudimos leer este documento» con sus acciones de reintentar / reemplazar / registrar manualmente.

> «Al intentar subir .doc: "Formato no compatible. Puedes subir PDF, Excel o CSV."»

**Implementado literal** en `documentRules.ts:36`, palabra por palabra.

### Nota 2 — Regla de habilitación del CTA «Siguiente»

> «Se habilita si existe al menos un documento verificado/leído o una deuda manual guardada. Documentos inválidos, bloqueados por contraseña o en procesamiento no habilitan el avance.»

**Implementado exactamente:** `canContinue = hasReadyDocs || manualDebts.length > 0`, con la regla citada en el código como M04-RGL-005 / OD-01.

> «Puede mostrarse un mensaje que se van a desechar o van a un repositorio de pendientes (no diseñado o pensado)»

La app **ya lo resuelve**: el banner `"<archivo>" queda fuera de este análisis hasta que lo resuelvas`. No es una divergencia — es un hueco del diseño que la implementación cubrió. Conviene que diseño lo formalice para que la próxima auditoría no lo lea como elemento extra.

### Nota 3 — Contador solo con documentos activos

> «Si un documento se elimina, deja de contar. Si está inválido o bloqueado, cuenta mientras siga activo en la lista.»

**Implementado:** el contador es `docs.length`, `removeDoc` saca el documento del arreglo, y los inválidos o bloqueados permanecen en la lista y siguen contando.

---

## 🏁 Veredicto

El estado con documentos está mejor que el inicial: la geometría de las filas calca el frame en los ocho puntos medibles —los gaps de 16, 4 y 8, el alto de 32, los divisores arriba y abajo incluido el del último documento— y la tipografía de `StatementDocRow` ya respeta el piso de Manrope en nombre y metadatos.

El único defecto visual real era el contador, que por estar anidado dentro del `<Text>` del título heredaba su tamaño y peso: se veía cuatro puntos más grande de lo diseñado y pegado al texto en lugar de alineado a la derecha.

Lo que queda no son defectos de implementación sino decisiones pendientes de diseño: un chevron que la app agrega y el Figma no tiene en ningún estado, un botón terciario cuya altura el diseño define distinta en dos frames, y un mensaje de documentos descartados que la app ya resolvió sobre un hueco que el propio diseñador marcó como «no diseñado o pensado». Los tres necesitan que diseño se pronuncie antes de que tenga sentido tocarlos.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-09-05 (#1) | 89/100 → 95/100 | Contador heredando la tipografía del título — corregido; chevron extra y altura del terciario pendientes de diseño |
