# Reformulación de M1-V40 — «documento no procesable» no es un criterio pre-subida

**Fecha:** 2026-08-25
**Origen:** QA reporta que el procedimiento manual de `CP-M1-ONB-007` no es ejecutable: el paso 3 pide verificar que «Analizar mis documentos / Comenzar diagnóstico permanece deshabilitado» ante un archivo no procesable, y eso no puede ocurrir — la procesabilidad la determina Kread **después** de enviar el documento.

**Fuentes leídas (no citadas de memoria):**
- `specs/matriz-v2.6/variantes-m1.psv` línea 46 (`M1-V40`) y 53 (`M1-V47`).
- `specs/matriz-v2.6/anexos-y-decisiones.psv` línea 9 (`M1-V38` → `M01-RGL-010`).
- `front-walvy` @ `expo/features/auth/ui/OnboardingDocScreen.tsx`, `OnboardingAnalysisScreen.tsx`, `expo/features/auth/utils/importErrorCode.ts`.
- `back-walvy` @ `src/imports/entities/statement-import.entity.ts`, migración `1786000022000-AddFailureReasonAStatementImports`.

**Alcance:** se corrige el **criterio de verificación** de V40, no la regla de negocio. `M01-RGL-010` está bien redactada; el defecto está en cómo el caso de prueba la tradujo a UI.

---

## 1. Qué dice hoy la matriz y qué dice el caso de prueba

`M1-V40` — Comportamiento esperado (columna E):

> No habilitar diagnóstico; pedir subir otro/revisar archivo.

`M01-RGL-010` — Criterio de aceptación:

> El documento queda identificado como Rechazado, No procesable o Desactualizado; se muestra una acción siguiente adecuada y el diagnóstico permanece bloqueado hasta contar con información suficiente.

Ninguna de las dos dice «botón deshabilitado». El procedimiento manual de `CP-M1-ONB-007` interpretó «no habilitar diagnóstico» como «el CTA queda gris en la pantalla de carga». Esa interpretación es la que no es ejecutable.

## 2. Por qué no es ejecutable

La admisión ocurre en dos momentos distintos, y sólo el primero es síncrono:

| Momento | Qué se evalúa | Dónde |
|---|---|---|
| **Pre-subida** (síncrono, local) | extensión/MIME, peso, duplicado, fecha inferida del nombre, contraseña de PDF | `OnboardingDocScreen.tsx:341-368` |
| **Post-subida** (asíncrono, Kread) | si el contenido es una cartola/estado de cuenta/informe CMF con datos extraíbles | `importErrorCode.ts` + `OnboardingAnalysisScreen.tsx:554-566` |

Un PDF corrupto, un `.xlsx` vacío o un binario renombrado a `.pdf` pasan **todos** los filtros pre-subida: extensión válida, peso válido, nombre válido. Entran a la lista y el CTA queda habilitado, porque `OnboardingDocScreen.tsx:563` es literalmente `disabled={!hasDocs}`. No hay información con la cual deshabilitarlo: el archivo todavía no salió del teléfono.

Y en la pantalla de análisis el CTA **tampoco** se deshabilita por un documento fallido: `OnboardingAnalysisScreen.tsx:782` sólo lo deshabilita mientras `loadingSummary || isPending`. El bloqueo del diagnóstico se implementa por otra vía: el semáforo pasa a rojo y el CTA primario **cambia de función** — `handleComenzar()` en rojo/amarillo abre el modal de información clave (`OnboardingAnalysisScreen.tsx:428-431`) en vez de navegar a `onboarding-first-ready`. En rojo no existe el secundario «Comenzar diagnóstico con esta base».

Es decir: el diagnóstico sí queda bloqueado, tal como pide `M01-RGL-010`. Lo que no existe — ni debe existir — es un botón deshabilitado.

## 3. Reformulación propuesta

**V40 se divide en dos criterios verificables por separado.**

### V40.a — Rechazo en admisión (síncrono, pre-subida)

**Disparador:** el archivo seleccionado incumple una condición verificable localmente (extensión/MIME no permitido, excede el peso máximo, duplicado en la selección).

**Comportamiento esperado:** el archivo **no se agrega a la selección**; se muestra el motivo en la misma pantalla de carga; el usuario puede elegir otro archivo.

**Oráculo:** el documento no aparece en el listado + se renderiza el bloque de error correspondiente (`Este formato no lo podemos usar` / `⚠ Archivo demasiado grande`). Determinista, sin red.

> Esto es lo que ya cubre la ruta de «formato no permitido» y no es lo que V40 quiere probar.

### V40.b — No procesable (asíncrono, post-subida)

**Disparador:** el archivo es admitido y subido, y el procesamiento determina que no contiene datos utilizables (Kread no reconoce un documento financiero válido).

**Comportamiento esperado:**
1. El documento se sube y aparece en el listado de la pantalla de análisis con estado terminal `failed`.
2. Queda **identificado con su causa**: etiqueta `No procesable` + `Sube una cartola, un estado de cuenta o un informe CMF.` (`importErrorCode.ts:21-22`).
3. **No se ofrece reintentar** — es un fallo permanente, no transitorio. La acción de recuperación es eliminar el documento (ícono de eliminar en la fila) y/o `Cargar más documentos`.
4. **El diagnóstico no se habilita:** si no queda base suficiente, el semáforo queda en rojo y el CTA primario no inicia el diagnóstico. El oráculo es **la ausencia de navegación a `onboarding-first-ready`**, no el estado `disabled` del botón.
5. El motivo queda **persistido**: `statement_imports.status = 'failed'` y `statement_imports.failure_reason` con el enum correspondiente (`statement-import.entity.ts:169-176`).

**Oráculo:** pasos 1-3 y 5 son deterministas y automatizables hoy. El paso 4, en su parte visual (copy del banner rojo, etiqueta del CTA), depende de la validación de Figma pendiente; en su parte funcional (no se navega al diagnóstico) es automatizable ya.

## 4. Nota aparte: V40 y V47 no deben compartir caso de prueba

Ambas variantes apuntan hoy a `CP-M1-ONB-007` y al mismo nodo Figma `3361:2744`. Esa es la raíz de la confusión del procedimiento manual. `M1-DP-005` ya cerró que V47 es **exclusivamente** un fallo técnico recuperable posterior a la admisión, con CTA primario `Reintentar`; V40 es un rechazo **permanente** del contenido, sin reintento. El código ya los distingue (`importErrorCode.ts`: `not_useful_document` sin reintento vs. `service` → `Error temporal. Inténtalo de nuevo en unos segundos.`), pero la matriz los mantiene apuntando al mismo CP. Corresponde separar: V40 → `CP-M1-ONB-007`, V47 → CP propio.

## 5. Lo que sí queda pendiente de diseño

Sólo el **estado visual agregado**: copy del banner rojo, etiqueta del CTA primario y la pantalla exacta del mensaje de rechazo (columna «pantalla exacta a validar» de V40). Los textos por documento (`No procesable` + hint) son constantes en código, no salen de un mockup — un locator sobre ellos es estable y no queda obsoleto cuando diseño cierre la definición.

## 6. Impacto

- **Matriz v2.6:** V40 pasa a `Ajustar` con esta precisión de D/E, en el mismo formato en que se documentó `M1-DP-005` para V47. No requiere una RN nueva: `M1-RN-ONB-006` / `M1-RN-ONB-007` se precisan.
- **QA:** el procedimiento manual de V40 se reescribe con los oráculos de §3. El paso 5 («queda registrado») no requiere logs: es una consulta a `statement_imports`.
- **Automatización:** se puede escribir el step definition de V40.b pasos 1-3 y 5 ahora. El estado visual agregado espera la definición de diseño.
- **Código:** sin cambios. El comportamiento actual satisface `M01-RGL-010`; lo que estaba mal era el criterio con que se lo estaba midiendo.
