# Resumen de sesión — M04, verificación de matrices y panel QA

**Rango:** 2026-09-11 a 2026-09-16. Para retomar en otra ventana sin releer todo el hilo.

---

## 1. Verificación de las matrices M04 contra código

- Verifiqué `back-walvy` `origin/qa` (primero en `515ddd9`, luego en `ad93b39`) contra:
  - `Walvy_M04_Matriz_Trazabilidad_Cliente_v1.1.xlsx` (93 obligaciones, 43 reglas, 25 contratos P4)
  - `Walvy_M04_Matriz_Validacion_Tecnica_v1.1.xlsx` (30 controles TEC)
- Generé las dos matrices de respuesta, en `entregas/`:
  - `Walvy_M04_Matriz_Trazabilidad_Cliente_v1.1_RESPUESTA_KABELI.xlsx`
  - `Walvy_M04_Matriz_Validacion_Tecnica_v1.1_RESPUESTA_KABELI.xlsx`
- Después apareció una entrega nueva, **`Walvy_M04_Matriz_Trazabilidad_Funcional_Definitiva_v1.1.xlsx`** (09-15, en `documentacion/modulo04/`, no en subcarpeta fechada). La verifiqué contra el mismo código.

**Hallazgo importante — `M04-RGL-006` revertida:**
La Definitiva volvió el texto de `M04-RGL-006` al de la v1.0 (*"Deuda registrada o detectada no equivale a deuda confirmada"*) y le quitó la cita a `TR-M04-051`/`TR-M04-053`, **contradiciendo el ruling explícito del PMO del 09-09** ("Guardar confirma" en alta manual, que la v1.1 sí había incorporado). Causa probable, no confirmada: la hoja `07_Reconciliacion_Producto` de la Definitiva declara su línea base como `Walvy_M04_Matriz_Trazabilidad_Cliente_v1.0.xlsx` — se reconcilió contra la v1.0, saltándose la v1.1.

**Estado:** pregunta abierta como **punto 11** en [`KabeliDev/front-walvy#176`](https://github.com/KabeliDev/front-walvy/issues/176) (bitácora de dudas M04 para el PM), 2026-09-16. **El código sigue implementando el ruling del 09-09** (`DebtsService.create` nace `confirmed`) mientras no haya respuesta — no tocar por este punto sin que Producto conteste.

Memoria: `project_m04_rgl006_definitiva_revierte.md`, `project_m04_respuesta_matrices_v11.md`.

---

## 2. Panel QA (`/dev/qa`) — dos PRs, ambos mezclados a `qa`

**[#281](https://github.com/KabeliDev/back-walvy/pull/281)** — plan de 3 fases (mezclado, `bd75ce4`):
1. Tarjeta "Ruta Despeje (M04)" leyendo `GET /debts/route/current` en lenguaje humano.
2. `POST /dev/seed-debt-cycle` + `GET /dev/debt-cycle/:debtId` — sembrar/leer `debt_cycle` desde el panel (esa tabla no tiene productor real; antes exigía SQL a mano).
3. Selector rápido de las tres cuentas del semáforo (`semaforo-verde/-amarillo/-rojo@ejemplo-walvy.cl`, clave `Walvy2026`).

**[#282](https://github.com/KabeliDev/back-walvy/pull/282)** — 6 commits de una revisión en vivo contra `api-qa.sonark.tech/dev/qa` (mezclado, `e00c865`), mismo patrón en todos: un mensaje o control que asumía algo del estado sin verificarlo:
1. Onboarding: `Puerta actual: —` no distinguía "nunca arrancó" de "ya terminó".
2. Kread: documento sin archivo parseado caía en la tabla de KPI vacía en vez de explicar por qué.
3. Movimientos + Deudas: mensaje "por diseño" falso para documentos fallidos; deuda `dismissed` ofrecía sembrar un ciclo sin ningún efecto en Ruta Despeje.
4. Ruta Despeje: glosario del motor (9 pasos, C×K×D, F1–F7, ownership M04/M05/M06) + `REASON_GLOSS` que traduce los `reasonCodes`.
5. Foco y perfil: llamaba a `/transactions`, endpoint que **no existe** — el real es `GET /financial-movements`. De paso, foco humanizado y tabla de movimientos real.

**Patrón que quedó establecido:** cuando el panel copia a mano un catálogo/diccionario que vive en otro archivo (CHECK de una migración, `REASON` de una regla, `VALID_FOCUS_IDS` de un DTO), se agrega un spec que extrae el original por regex y compara — mismo criterio que ya tenía `update-onboarding-step.dto.spec.ts`. Tres instancias nuevas: `seed-debt-cycle.dto.spec.ts`, `qa-panel-reason-gloss.spec.ts`, `qa-panel-focus-labels.spec.ts`. Las tres se verificaron mutando el archivo a propósito y confirmando que el test señala el drift exacto.

**Antes de mezclar #282:** suite completa del repo (102 suites / 1195 tests) en verde, no sólo `src/dev`; lint y `tsc` globales limpios; CI (GitHub Actions) en verde; confirmado en vivo que `api-qa.sonark.tech/dev/qa` ya sirve el HTML nuevo.

Memoria: `project_qa_panel_mejoras_281_282.md`.

---

## 3. Revisión del PR de Sergio — RD-02 Simulación (M05)

**[#280](https://github.com/KabeliDev/back-walvy/pull/280)** (`feature/m5`, **abierto, no mezclado** — es un PR grande de M05 con dos commits que tocan M04):
- `PrudentialOutcomePort` con envelope (`outcome` + `ruleVersion` + `evaluatedAt` + `reasonCode`) — adapter siempre `no_evaluable` (correcto: no existe fórmula del colchón operativo todavía).
- Endpoints `POST /debts/route/simulate` / `.../simulation/accept` / `.../simulation/rollback`, sobre `sustainability-gate.rule.ts` + `selected-plan.rule.ts` (ya existían, sólo faltaba cablearlas).
- Revisé sólo la parte de M04 (no el resto del PR de M05): sin efectos secundarios financieros, rollback de un nivel, `mode` nunca llega a `recomendacion` mientras el outcome sea `no_evaluable` — probado explícito en el e2e. 525 tests en verde, lint/tsc limpios.
- Comentario de revisión: [`#280`](https://github.com/KabeliDev/back-walvy/pull/280#issuecomment-5691767718). Actualicé [`#276`](https://github.com/KabeliDev/back-walvy/issues/276#issuecomment-5691769059) (queda abierto hasta el merge de `#280` y hasta que exista la política prudencial real).

Memoria: `project_m04_rd02_simulacion_construida.md`.

---

## Pendiente — en orden de qué desbloquea qué

1. **Respuesta de Producto sobre RGL-006** (issue `#176` punto 11). Bloqueante para saber si el alta manual sigue naciendo `confirmed` o si hay que revertir. No hacer nada de código sobre este punto hasta que conteste.
2. **Mezclar `#280`** a `qa` cuando Sergio y su reviewer lo den por listo (es su PR, no mío decidir el momento).
3. **RGL-031 · Proyección/cronograma** — el siguiente ítem que estábamos por diseñar cuando surgió el pedido del panel. Es 100% de M04, no bloqueado por nadie (a diferencia de casi todo lo demás en la matriz). Hallazgo de esa investigación: existen **tres tablas ya creadas y sin una sola línea de código que las use** — `debt_projection` (el snapshot que pide `P4-CNT-023`, con `rule_version`/`assumptions_used`), `debt_payoff_schedule` (cronograma de una simulación aceptada, cuelga de `debt_payoff_simulation`), y `debt_schedules` (calendario de cuotas). Antes de diseñar, mirar el patrón de invalidación por cambio material que Sergio ya construyó en `#280` (`debt-fingerprint.util.ts`) para no inventar una segunda forma de invalidar.
4. **Guardrail de dirección de `DEU_09`** (categorías) — chico, defensivo, mencionado en `project_rgl021_naturaleza_financiada.md` punto 3: `assertCategoryLeaf` no valida dirección, así que un egreso puede alojarse en `DEU_09` por la ruta manual. No iniciado.
5. **Resto de obligaciones "no implementada"** de la matriz (bajan de prioridad, todas bloqueadas por otro equipo o de alcance menor): `hechosCausales` (M05, RGL-020/021), escritor real de `debt_cycle` (M06), etiquetas funcionales MVP (condicionadas a que exista el dato que las sostenga).

## Dónde está todo

- Matrices de respuesta: `entregas/Walvy_M04_Matriz_*_RESPUESTA_KABELI.xlsx`
- Matriz Definitiva: `documentacion/modulo04/Walvy_M04_Matriz_Trazabilidad_Funcional_Definitiva_v1.1.xlsx`
- Bitácora de dudas M04 (Producto): `KabeliDev/front-walvy#176`
- Issues de seguimiento: `KabeliDev/back-walvy#189` (plan M04-A/M04-B), `#276` (RD-02), `#280` (PR de Sergio, abierto), `#281`/`#282` (panel QA, mezclados)
- Memoria (`~/.claude/projects/.../memory/`): `project_m04_respuesta_matrices_v11.md`, `project_m04_rgl006_definitiva_revierte.md`, `project_qa_panel_mejoras_281_282.md`, `project_m04_rd02_simulacion_construida.md`, `project_m04_rd02_simulacion_plan.md`, `project_rgl021_naturaleza_financiada.md`
