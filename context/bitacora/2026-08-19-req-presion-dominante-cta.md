# Requerimiento — presión principal única y CTA dominante (`M1-V57`)

Fecha: 2026-08-19
Estado: **pendiente de implementación**
Reglas: `M1-RN-ONB-011` / `M1-RN-ONB-012` · assessment `M01-RGL-015` / `M01-RGL-016`
Variante: `M1-V57` (Matriz v2.6) · caso QA `CP-M1-ONB-015` · issue `RM1-19` (#39)
Código base: back `walvy/main` `bbac9c0` · front `walvy/main` `d02bb48`

## Por qué existe este documento

La validación de `M1-V57` sobre esos dos SHA dio **no cumple** en las dos mitades de la
regla, y por causas distintas:

| Mitad de la regla | Falla concreta |
|---|---|
| Una presión principal única | `/summary` emite **seis señales** (`detected.*`) más el ratio; la pantalla de diagnóstico no lee ninguna. La card "Señales detectadas" es copy fijo por color en `SEMAFORO_CONFIG` (`OnboardingFirstReadyScreen.tsx:49-101`), incluido el `"Revisar 5 movimientos pendientes"` con el 5 escrito a mano (L81) |
| Un CTA dominante | Es único por construcción, pero no está derivado ni acciona nada: el CTA primario (L370) y el enlace terciario (L383) ejecutan la **misma** función `goToTabs` (L294-297) → `advanceOnboardingStep` + `router.replace("/(tabs)")`. "Atender riesgo de sobrecarga" no lleva a atender nada |

No es un ajuste de copy. Falta la capa que selecciona: hoy no existe, ni en backend ni en
front, ninguna lógica que elija una señal entre varias.

## El catálogo no está bloqueado

El diagnóstico del 2026-08-12 dejó `RM1-19` bloqueado por "no existe catálogo de
`dominant_pressure_code`". Revisando los `COMMENT`/`CHECK` del esquema, la afirmación hay
que corregirla: **el catálogo existe en la base**, sólo que con otro nombre de columna.

`user_month_diagnosis_summary` (migración `1786000012000`, L250-290) ya trae:

| Columna | Contenido | Uso en este requerimiento |
|---|---|---|
| `dominant_signal_type` | CHECK de 7 valores: `payment`, `debt`, `budget`, `leak`, `categorization`, `data_quality`, `none` | **catálogo de presión principal** |
| `dominant_signal_ref_id` | UUID de la entidad que origina la señal | destino real del CTA |
| `dominant_cta_type` | CHECK de 9 valores: `complete_onboarding`, `improve_profile_precision`, `upload_document`, `confirm_debt`, `view_ruta_despeje`, `review_payment`, `adjust_budget`, `review_category`, `no_dominant_cta` | **catálogo de CTA dominante** |
| `dominant_cta_ref_id` | UUID del objeto del CTA | navegación con parámetro |
| `cta_reason_codes` / `traffic_light_reason_codes` | `text[]` | señales secundarias y trazabilidad |
| `rule_version`, `computed_at`, `source_watermark_at` | versionamiento | cierra `M1-RN-ONB-018` / `RM1-21` |
| `dominant_pressure_code`, `dominant_cta_code` | `varchar(80)` libres | quedan **sin usar** en MVP (ver "Fuera de alcance") |

El `COMMENT` de `dominant_cta_type` cita la fuente: *Rector T10R002-T10R008*. Es el modelo
previsto por el cliente, escrito en el esquema antes que en el código.

Lo único que falta ratificar con el cliente es **el orden de prioridad entre las 7 señales**
y el copy visible. No la existencia del catálogo. Eso desbloquea `RM1-19` sin esperar una
definición nueva.

## Alcance MVP

Contra `mvp-scope.csv` (fila 30 onboarding, fila 140 recomendaciones por pantalla):

| Capacidad | MVP | Sustento |
|---|---|---|
| Motor de reglas que elige una señal y una acción por pantalla | ✅ | fila 140: *"motor de reglas por pantalla disparado por metas de categoría, umbrales, semáforo, vencimientos"*; fila 30: *"un CTA claro por paso"* |
| Explicar qué señal disparó el CTA | ✅ | fila 140: *"debe explicar brevemente qué señal la disparó"* |
| Señales secundarias visibles como información | ✅ | fila 30: semáforo + primeras recomendaciones |
| Persistir el diagnóstico con versión de regla | ✅ | `M1-RN-ONB-018`; la tabla existe |
| Ranking por modelo/IA propia | ❌ | fila 140: *"no depender de IA opaca o de un modelo propio"* |
| Señales fuera de los 7 tipos del CHECK | ❌ | el CHECK las rechaza; ampliarlo requiere decisión del cliente |
| Presión consolidada multi-mes | ❌ | MVP es la primera lectura del mes cargado |

La tabla soporta más de lo que el MVP promete (`dominant_pressure_code`, `debt_health_status_id`,
`visible_savings_capacity_*`). Capacidad de esquema ≠ alcance.

## Backend

Precedente de estilo obligatorio: `src/debts/rules/debt-severity.rule.ts` — función pura,
`RULE_VERSION` exportada, `reasons[]` con códigos, `redirectTarget`, y el criterio explícito
*"lo peor manda"*. La regla de presión se escribe igual.

### R-B1 · Regla pura de presión dominante

Nuevo `src/health/rules/dominant-pressure.rule.ts`.

- Entrada: totales y flags del mes (los que hoy calcula `computeSummary`), suficiencia,
  conteo de movimientos sin categorizar, deudas confirmadas/detectadas, pagos próximos a
  vencer, desvío de presupuesto.
- Salida: `{ dominantSignal, dominantSignalRefId, dominantCta, dominantCtaRefId, secondarySignals[], reasonCodes[], ruleVersion }`.
- `dominantSignal` ∈ los 7 valores del CHECK. `dominantCta` ∈ los 9.
- **Una sola** señal dominante. Todas las demás evaluadas van en `secondarySignals`, nunca
  se pierden: eso es la mitad "el resto queda secundario" de `M1-V57`.
- Función pura y sincrónica, sin repositorios: testeable por tabla de casos.

**Aceptación:** con dos o más señales activas simultáneamente, la función devuelve
exactamente una `dominantSignal` y lista el resto en `secondarySignals`. Determinista:
misma entrada → misma salida.

### R-B2 · Orden de prioridad (propuesta a ratificar)

Derivado de `message_rule.priority` ya sembrado en la migración `1786000014000` (L304-317) y
del guardrail `RB-FM-002`/`RB-FM-005` — *una señal crítica de salud financiera siempre
prevalece sobre el foco declarado*.

| # | `dominant_signal_type` | Dispara cuando | `dominant_cta_type` | `message_rule` de origen |
|---|---|---|---|---|
| 1 | `data_quality` | suficiencia `insufficient` / `blocked` | `upload_document` | `debt_health_insufficient_data` (prio 1) |
| 2 | `payment` | pago agendado vence en ≤ 3 días o vencido | `review_payment` | `payment_due_3d` (prio 1) |
| 3 | `debt` | deuda confirmada bajo presión, o deuda detectada sin confirmar | `view_ruta_despeje` / `confirm_debt` | `debt_health_pressured`, `confirm_detected_debt` (prio 1) |
| 4 | `budget` | gasto sobre el 80% del presupuesto | `adjust_budget` | `budget_80pct` (prio 2) |
| 5 | `leak` | fugas / gasto hormiga detectados | `review_category` | `leaks_detected` (prio 2) |
| 6 | `categorization` | hay movimientos sin categorizar | `review_category` | `uncategorized_movements` (prio 3) |
| 7 | `none` | ninguna señal activa (semáforo verde limpio) | `improve_profile_precision` | `debt_health_healthy` (prio 4) |

`data_quality` va **primero a propósito**: `M1-RN-ONB-010` prohíbe leer insuficiencia como
riesgo financiero. Si falta base, la presión es del dato, no del dinero, y el CTA es cargar
documento — nunca un CTA financiero.

Esta tabla es el entregable a ratificar con el cliente. Se implementa como constante
ordenada en el archivo de la regla, con el número de prioridad explícito, para que
ratificarla o cambiarla sea editar una lista y no reescribir la lógica.

### R-B3 · Entidad y escritura del read model

- Crear la entidad TypeORM de `user_month_diagnosis_summary` (hoy no existe ninguna).
- El `COMMENT ON TABLE` dice *"No se escribe directamente: solo el job la actualiza"*. Se
  respeta: **un único servicio escritor** en `src/health`, invocado por evento, sin endpoint
  de escritura. El disparador ya está declarado en `app_config`:
  `diagnosis.recalc_trigger = "on_movement_change"` (migración `1786000014000`).
- Se recalcula al quedar un import en `parsed` y al cambiar movimientos del mes.
- Escribe `rule_version` (constante exportada de R-B1) y `computed_at` en cada evaluación.
- `traffic_light_reason_codes` y `cta_reason_codes` se llenan siempre, incluso en verde.

**Aceptación:** tras un import parseado existe exactamente una fila por `(user_id, month)`
con `dominant_signal_type` y `dominant_cta_type` no nulos y `rule_version` poblada. Un
segundo recálculo actualiza la fila, no inserta otra.

### R-B4 · Contrato expuesto

Extender la respuesta de `GET /statement-imports/:id/summary` y su variante batch
(`statement-import.service.ts:41-68`) con un bloque nuevo, sin tocar los campos existentes
—`detected` y `semaforo` siguen igual para no romper `OnboardingAnalysisScreen`:

```jsonc
"diagnosis": {
  "dominantSignal": "debt",
  "dominantCta": { "type": "view_ruta_despeje", "refId": "…", "deepLink": "/debts/ruta-despeje" },
  "signals": [
    { "type": "debt",           "level": "attention", "label": "Compromisos", "dominant": true  },
    { "type": "categorization", "level": "attention", "label": "Movimientos", "dominant": false, "count": 5 },
    { "type": "budget",         "level": "ok",        "label": "Margen",      "dominant": false }
  ],
  "reasonCodes": ["debt_pressure_ratio", "uncategorized_movements"],
  "ruleVersion": "v1_mvp"
}
```

- `signals[]` es la fuente de la card "Señales detectadas": **una entrada por señal
  evaluada, con su nivel real**, no tres etiquetas fijas.
- `count` es lo que resuelve el `"Revisar 5 movimientos pendientes"` hardcodeado.
- `deepLink` sale de `message_rule.deep_link`, ya sembrado.
- Exactamente un elemento con `dominant: true`. Invariante a testear.

### R-B5 · Exponer el estado en onboarding

`toOnboardingPublic` (`user-onboarding.service.ts:170-186`) expone `pendingBestAction` y
**nadie lo escribe** — no está en `update-onboarding-step.dto.ts`, que sólo acepta
`currentGate` y `resumeState`. Que lo escriba el servicio de R-B3 con el `dominant_cta_type`
vigente, y que `GET /auth/onboarding` agregue `generalTrafficLightStatus`,
`sufficiencyStatus` y `diagnosticStatus`, hoy declarados en la entidad
(`onboarding-state.entity.ts:107-139`) y nunca escritos.

Sigue siendo escritura de servidor: **no** se agregan al DTO del PATCH. Un cliente no debe
poder declararse su propia presión dominante — es el mismo defecto ya registrado en el
issue #68 para los checkpoints.

**Aceptación:** `pendingBestAction` cambia sin que el cliente lo envíe, y el PATCH lo rechaza
si alguien lo manda en el body.

## Frontend

### R-F1 · Sacar las señales del código

En `OnboardingFirstReadyScreen.tsx`, `SEMAFORO_CONFIG` (L49-101) se reduce a lo que es
presentación pura del color: `statusLabel`, `statusColor`, `gradient`, `cardBorder`,
`dotsBorder`, `mascot`. Salen del archivo `signals`, `actionText` y `actionCTA`.

La card "Señales detectadas" (L346-360) itera `diagnosis.signals[]`: label, nivel e icono por
`type`. La señal dominante se marca visualmente; las demás quedan como información secundaria
en la misma lista.

**Aceptación:** no queda ningún literal de señal ni de CTA en el archivo. Con dos payloads
distintos del mismo color, la pantalla muestra contenidos distintos.

### R-F2 · Un CTA que accione

El bloque de acción (L363-373) toma `diagnosis.dominantCta`:

- texto desde el catálogo de copy por `dominant_cta_type`;
- `onPress` navega al `deepLink` con `refId`, **no** a `/(tabs)`;
- persiste el avance de onboarding antes de navegar, como hoy.

El enlace terciario "Ver mi Perfil Financiero" (L383-384) se mantiene como salida secundaria,
pero **deja de compartir handler con el CTA**: hoy ambos son `goToTabs` (L294-297) y por eso
el CTA es decorativo. Si el destino de Perfil Financiero sigue fuera de M1 (`RM1-22`), va a
`/(tabs)` explícitamente y con su propia función, para que la diferencia quede en el código.

El `TabBarStatic` (L388) es chrome de la app, no compite como CTA: se deja.

**Aceptación:** con `dominantCta = view_ruta_despeje`, tocar el CTA no aterriza en `/(tabs)`.
CTA y enlace terciario no invocan la misma función.

### R-F3 · `gray` / sin diagnóstico

Hoy `TrafficLight` no tiene `gray` (L32) y `VALID_LIGHTS` sólo admite tres (L47), así que un
`gray` del backend se descarta en silencio y la pantalla se queda en el `green` inicial del
`useState` (L265). Agregar el cuarto estado, con `dominantSignal = data_quality` y CTA
`upload_document`.

Es una **dependencia de `RM1-18`**: mientras `computeSummary` haga `ratio = 1` sin ingresos y
pinte rojo (`statement-import.service.ts:672-674`), un usuario sin ingresos detectables verá
Riesgo con un CTA financiero — exactamente lo que `M1-V56` prohíbe. Este requerimiento define
qué hacer con `gray`; el umbral y el cuarto estado los corrige `RM1-18`.

### R-F4 · Tipos y mocks

`ImportSummaryResponse` / `ImportSummaryBatchResponse` (`expo/api/types/cartola.ts:105-147`)
suman el bloque `diagnosis`. `mergeSemaforos` y el merge del batch
(`statementImportService.ts:341-386`) deciden el diagnóstico del conjunto aplicando la regla
sobre los totales combinados, no eligiendo el de un import al azar. El `MOCK_IMPORT` (L279-292)
y los mocks de `onboarding-analysis.tsx` (L31-49) se actualizan.

`devLight` se conserva y se amplía a un `devDiagnosis` para poder demostrar `CP-M1-ONB-015`
sin fabricar datos en base.

## Criterios de aceptación de la variante

`CP-M1-ONB-015` hoy no es reproducible: la pantalla da el mismo copy para cualquier
combinación de señales dentro de un mismo color. Con esto, el caso se prueba así:

1. Usuario con **tres señales activas a la vez** (deuda bajo presión + 5 movimientos sin
   categorizar + presupuesto sobre 80%).
2. La pantalla muestra **una** señal marcada como dominante y **un** CTA.
3. Las otras dos aparecen en la lista secundaria, sin CTA propio.
4. El CTA navega al destino de la señal dominante.
5. La fila de `user_month_diagnosis_summary` registra la misma señal, el mismo CTA,
   `rule_version` y los `reason_codes` de las tres señales.
6. Bajando la señal dominante (confirmando la deuda), el recálculo promueve la siguiente en
   prioridad y cambia el CTA.

El punto 5 es la evidencia que la fila "Evidencia QA múltiples señales por enlazar" pide, y
que hoy no puede existir porque nada se persiste.

## Fuera de alcance

- `dominant_pressure_code` / `dominant_cta_code` (`varchar(80)` libres). El MVP usa los
  `*_type` con CHECK. Los `*_code` quedan nulos hasta que el cliente defina su vocabulario;
  poblarlos con valores inventados sería crear un catálogo paralelo.
- Ampliar los CHECK de 7/9 valores. Si una señal nueva no cabe, es decisión del cliente y
  migración aparte — no se toca el CHECK para acomodar el código (`M1-RN-ONB` no lo pide).
- Umbrales del semáforo 0,80 → 0,90, cuarto estado y override `mora_confirmada`: son
  `RM1-18`. Este requerimiento los consume, no los corrige.
- Gate de suficiencia con sus cuatro salidas: `RM1-17`. R-B1 lo recibe como entrada; si aún
  no existe, se alimenta de `computeCompleteness` (`OnboardingAnalysisScreen.tsx:221-229`)
  movido al backend, que es donde debió estar siempre.
- Eventos mínimos de `M01-RGL-017`.
- Frontera con Perfil Financiero: `RM1-22`.

## Dependencias y orden

```
RM1-17 (suficiencia) ─┐
RM1-18 (semáforo)    ─┼─→ R-B1 → R-B2 → R-B3 → R-B4 → R-F1 → R-F2 → R-F3 → R-F4
                      │              └→ R-B5 (paralelo)
Ratificación tabla R-B2 ┘
```

R-B1 y R-B2 se pueden escribir y testear sin `RM1-17`/`RM1-18`: son función pura sobre una
entrada declarada. Lo que no se puede cerrar sin ellos es el comportamiento en `gray`.

## Decisiones abiertas

1. **Orden de prioridad de R-B2** — propuesta arriba, requiere ratificación. Es lo único que
   bloquea el cierre funcional de la variante.
2. **Copy visible por `dominant_cta_type`** — nueve textos. Hoy hay tres, escritos en el
   front. Los de `message_rule.name_es` sirven de borrador, no de fuente aprobada.
3. **Destino de `improve_profile_precision`** — apunta a Perfil Financiero, que es `RM1-22`.
   Mientras siga fuera de M1, este CTA cae a `/(tabs)` y hay que decir por escrito que es
   provisorio.
4. **`M01-RGL-016`** — el cierre del onboarding debe colgar de la primera lectura persistida.
   R-B3 crea por fin esa lectura persistida, así que habilita el cambio; el cambio en sí es
   el issue #68 y no se hace acá.
