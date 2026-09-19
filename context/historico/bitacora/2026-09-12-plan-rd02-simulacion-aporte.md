# M04 · RD-02 Simulación de aporte — plan para cablear en `origin/qa`

**Fecha:** 2026-09-12 · **Responsable:** Miguel Herize
**Base verificada:** `back-walvy` `origin/qa` `0945fb8` · `front-walvy` `origin/qa` `bef3b65`
**Dispara este plan:** paquete de documentación actualizado del cliente (`documentacion/modulo04/modulo04_12-09/`,
correo "M04 – Documentación para implementación", 2026-09-12) + Figma de Ruta Despeje / Resultado con el
simulador de aporte adicional.

---

> **Decisión 2026-09-12:** se optó por no adelantar con un adapter stub. [`back-walvy#276`](https://github.com/KabeliDev/back-walvy/issues/276)
> registra la dependencia explícita: la simulación necesita M05 (outcome prudencial) y M06 construidos antes
> de poder implementarse, consistente con la clasificación M04-B de `#189`. La opción (A) del §2 queda
> documentada como camino alternativo si esto cambia, no como plan vigente.
>
> **Corrección 2026-09-14 (conversación con PMO):** el dev igual construyó el adapter stub y dejó comentario
> en `#276` explicando que el bloqueo real no es el puerto, es el *valor*. El pedido original a Producto
> ("definan piso mínimo + porcentaje") **estaba mal planteado** — confirmado en `Matriz_Validacion_Tecnica
> v1.1`, control `TEC-M4-017`: *"no exigir fórmula prudencial dentro de M04"*, *"sin 5% anterior"*.
> `P4-CNT-022` no es un parámetro a configurar en M04: es un gate de 3 estados
> (`positivo`/`cero_no_recomendado`/`no_evaluable`) que **M05 debe producir y M04 solo consume**. Lo que
> falta no es una decisión de Producto sobre un número — es el contrato M05→M04 que entregue ese outcome
> con versión y evaluabilidad. Ver §6 (nuevo) para el hallazgo de `D-M04-RESERVA-01`, sin resolver.
>
> **Respuesta de Walvy 2026-09-14 (mismo día, vía PMO):** confirmó exactamente el diagnóstico y cerró la
> pregunta por `D-M04-RESERVA-01` — la decisión **existe y está cerrada del lado de Walvy**, pero **nunca
> se aterrizó en la entrega** que recibimos. Va a "sacar la propagación" y actualizar el paquete. Ver §6
> para el detalle capa por capa y qué sigue exactamente sin cerrar.

## 0 · Tensión que hay que resolver antes de programar

**`back-walvy#189` (tracking M4) tiene "Simulación RD-02" clasificada como M04-B, después del 30 de
septiembre, bloqueada por M05.** `FLOW-M04-020` (6) y `FLOW-M04-021` (2) están sin marcar, con nota
`M05, M06` como dependencia. Si la intención es adelantar esta pieza ahora, hay que decidirlo explícitamente
con Producto/Erick — este plan no reabre esa clasificación por su cuenta, la deja escrita para que se
confirme o se descarte.

Lo que sí cambia el cálculo: **la regla no está bloqueada por lógica, está bloqueada por un puerto que no
existe.** Ver §2.

---

## 1 · Punto de partida — qué existe y qué no (verificado en código)

| Pieza | Estado |
|---|---|
| `sustainability-gate.rule.ts` + spec — 3 modos (`recomendacion` / `simulacion_referencial` / `completar_informacion`) | ✅ Completa, probada, `RULE_VERSION` fijo |
| `sustainability-gate.persistence.ts` (`toSustainabilityPersistence`) | ✅ Completa |
| `selected-plan.rule.ts` + spec — `acceptSimulation` / `executeRollback` / `applyMaterialChanges` / `cancelPreview` | ✅ Completa, probada |
| Tabla `debt_payoff_simulation` + entidad `DebtPayoffSimulation` | ✅ Existe, con `simulation_status` (`draft`/`active`/`archived`) que calza 1:1 con preview/seleccionado/anterior |
| Entidad registrada en TypeORM | ⚠️ Solo en `app.module.ts:227` (para que la migración la reconozca). **No está en `DebtsModule.forFeature`, ningún servicio la inyecta** |
| Endpoint de preview / aceptar / rollback | ❌ No existen. `DebtsController` solo tiene `route/current`, `route/apply`, `route/close-debt` |
| Puerto para el outcome prudencial de M05 (`PrudentialOutcome`) | ❌ No existe ningún `*_PORT` ni adapter — a diferencia de `PRESSURE_INPUTS_PORT`, que sí tiene puerto + adapter compuesto |
| M05 — ingreso/headroom (`PressureInputsPort`) | ✅ Ya no es el `NullPressureInputsAdapter` que describía la deuda técnica del 06-09: hoy `CompositePressureInputsAdapter` combina `BudgetPressureInputsAdapter` (M05) + `PaymentTrackingPressureInputsAdapter` (M06). **Esto estaba desactualizado en la deuda técnica; hay que corregirlo ahí también.** |
| M05 — D01 capacidad de ahorro (`savings-availability.rule.ts`, `computeCapacidadAhorro`) | ✅ Mergeado (PR #270, feature/m5). `CA = ingresoMensual - gastoTotalMes`, `null` si no hay ingreso válido |
| Front — pantalla de simulación | ⚠️ `debtsService.ts` ya manda `extraMonthlyPayment` en el body de `POST /debts/route/apply`, pero el propio comentario del archivo dice que **el backend lo ignora**. No hay llamada a un endpoint de simulación en ningún lado |
| Contrato funcional RD-02 (preview, outcomes positivo/0/no_evaluable/manual, aceptar como plan, rollback de un nivel) | ✅ Confirmado en `00_LEEME_ENTREGA_KABELI.md` del paquete 12-09, y coincide campo a campo con lo ya escrito en el código |
| Materialización visual (Figma) de las variantes del simulador | ❌ Pendiente del lado Walvy — el correo del 12-09 lo declara explícitamente fuera de este contrato: "el comportamiento funcional ya está definido; falta su aterrizaje visual" |

**La foto en una frase:** las dos reglas están escritas, probadas y de acuerdo con el contrato del cliente.
Lo que falta no es diseño de reglas — es el cableado (endpoint + DTO + repositorio) y una entrada real o de
transición para el outcome prudencial de M05.

---

## 2 · La pieza que de verdad decide el alcance: `PrudentialOutcome`

`sustainability-gate.rule.ts` recibe `PrudentialOutcome | null` y con eso solo puede llegar a
`recomendacion` si `outcome.state === 'positivo'`. Hoy nada produce ese objeto. Dos caminos, no
mutuamente excluyentes:

**A · Adapter stub (`NullPrudentialOutcomeAdapter`), sin esperar a M05.**
Mismo patrón que ya existía para `PressureInputsPort` antes de que M05 entregara: un puerto
`PRUDENTIAL_OUTCOME_PORT` con un adapter que siempre devuelve `{ state: 'no_evaluable' }` (o
`hasPrudentialPolicy: false`). Con eso el gate ya cae solo, honestamente, en `simulacion_referencial` o
`completar_informacion` — nunca en `recomendacion` fabricada. **Esto desbloquea todo lo de abajo hoy,
sin ningún input nuevo de M05.**

**B · Adapter real usando D01 (`computeCapacidadAhorro`), a confirmar con Sergio (M05) y Producto.**
`capacidadAhorro` (`CA = I - E`) es estructuralmente el mismo tipo de dato que pide `PrudentialOutcome`:
`null` → `no_evaluable`; `<= 0` → `cero_no_recomendado`; `> 0` → `positivo` con `sustainableAmount`. **No
está confirmado que D01 sea *la* política prudencial que `P4-CNT-021/022` exige** (podría faltarle el
colchón operativo mínimo — la entidad `DebtPayoffSimulation` ya tiene columnas separadas
`operational_buffer_amount` y `available_space_amount`, lo que sugiere que el diseño original esperaba un
tercer número, no solo CA). **No inferir esto por analogía — es la pregunta a hacer.**

Recomendación: implementar (A) ahora, dejar (B) como spike de una tarde una vez que Sergio confirme si D01
es o no la fuente, y no bloquear el resto del trabajo en esa respuesta.

---

## 3 · Qué hay que construir

### 3.1 · Backend — cableado (esfuerzo bajo, sin bloqueo técnico)

1. **`PRUDENTIAL_OUTCOME_PORT`** (`src/debts/ports/prudential-outcome.port.ts`) + `NullPrudentialOutcomeAdapter`
   — mismo patrón que `pressure-inputs.port.ts`.
2. **`DebtPayoffSimulation` al `forFeature` de `DebtsModule`** + repositorio inyectado en un nuevo
   `SimulationService` (no meterlo en `RouteService`, que ya hace demasiado — separar por la misma razón
   que ya separaron `SituationsService`).
3. **Tres endpoints en `DebtsController`**, antes de `@Get(':id')` (mismo cuidado de orden de rutas que
   `route/current`/`route/apply`):
   - `POST /debts/route/simulate` — preview. Llama `evaluateSustainability` + `toSustainabilityPersistence`.
     **Decidir con Producto si el preview persiste como `draft` o es solo respuesta HTTP sin fila** — es la
     pregunta que ya estaba abierta en la matriz de impacto M1 y sigue sin cerrar. Mi lectura: no persistir
     el preview (`draft` efímero, solo en memoria) y persistir recién al aceptar — reduce filas huérfanas y
     el rollback de un nivel de `selected-plan.rule.ts` no necesita el draft, solo el plan aceptado anterior.
   - `POST /debts/route/simulation/accept` — llama `acceptSimulation`. Escribe `active` (nuevo) y pasa el
     anterior `active` a `archived`.
   - `POST /debts/route/simulation/rollback` — llama `executeRollback`. Restaura el `archived` a `active`.
4. **DTOs** con el monto manual opcional (`manualAmount`), siguiendo el estilo de `CloseDebtDto`.
5. **Invalidación (`applyMaterialChanges`)**: enganchar en `evaluateAndPublish` de `RouteService` — un
   cambio material en la ruta (nueva deuda, cierre, cambio de saldo) debe invalidar el rollback disponible.
   Esto es lo único que toca `RouteService` existente; todo lo demás es aditivo.

### 3.2 · Backend — qué NO hacer en este trabajo

- No tocar `PressureInputsPort` ni `CompositePressureInputsAdapter` — eso es otro eje (C×K×D), no el gate
  prudencial.
- No inventar un cálculo de "aporte sostenible" propio en M04 — eso es exactamente lo que `§16` prohíbe
  ("M04 no reconstruye la política prudencial").
- No usar `%` de "capacidad de ahorro comprometida" en ningún response — ya fue reemplazado por
  `health.status` según `2026-09-1x` (`project_m04_resultado_figma_vs_ruling` en memoria).

### 3.3 · Front — qué puede avanzar ya, qué no

- **Puede avanzar sin esperar Figma:** cablear `debtsService.ts` a los tres endpoints nuevos, sacar el
  `extraMonthlyPayment` muerto de `applyRoute`, y usar la card neutra/existente de Resultado para pintar los
  tres modos (`recomendacion` / `simulacion_referencial` / `completar_informacion`) con el copy mínimo que ya
  define el contrato — sin las variantes visuales finales.
- **Debe esperar:** el pixel-perfect de "aporte recomendado / sin aporte recomendado / no evaluable" y el
  botón de volver al plan anterior — el correo del 12-09 los deja fuera a propósito.

---

## 4 · Orden sugerido

1. Confirmar con Producto/Erick si esto se adelanta respecto a `back-walvy#189` (M04-B, post 30-sep) o se
   deja donde está clasificado.
2. Si se adelanta: opción (A) del §2 primero — puerto + adapter stub. Sin eso no hay nada que exponer.
3. Endpoints + `SimulationService` + DTOs (3.1, puntos 1-4).
4. Invalidación del rollback enganchada a `evaluateAndPublish` (3.1, punto 5).
5. Tests: extender los specs que ya existen de `sustainability-gate` y `selected-plan` con los casos de
   integración (controller + servicio + repo), no reescribir la lógica de regla que ya está probada.
6. Front: cableado de servicio + estados mínimos (3.3), en paralelo al paso 3 si hay banda.
7. Spike D01 (opción B del §2) una vez Sergio confirme si `capacidadAhorro` es la fuente — no bloquea 1-6.

## 5 · Preguntas para Walvy / Producto (no resolver por intuición)

- ¿El preview de simulación (`draft`) se persiste o es efímero? (ver 3.1.3 — mi propuesta es efímero, a
  confirmar).
- ~~¿`capacidadAhorro` (D01, M05) es la fuente del `PrudentialOutcome`...?~~ **Cerrada 2026-09-14: no.**
  `P4-CNT-022` no es un número a configurar/derivar en M04 — es un gate de 3 estados que M05 debe producir.
  D01 no es un candidato válido sin que Walvy lo confirme explícitamente como tal (ver §6).
- ¿Se adelanta "Simulación RD-02" respecto a la fecha post-30-sep de `back-walvy#189`, dado que la
  documentación y el Figma ya llegaron?
- **Nueva (2026-09-14):** ¿qué dice `D-M04-RESERVA-01`? Solo tenemos el ID citado, no su contenido — ver §6.
- **Nueva (2026-09-14):** ¿cuándo entrega M05 el contrato `M05 → M04` con el outcome prudencial
  (`positivo`/`cero_no_recomendado`/`no_evaluable`) + versión + evaluabilidad? Es el único insumo real que
  falta — no hay decisión de Producto pendiente sobre un parámetro.

## 6 · `D-M04-RESERVA-01` — resuelto por Walvy el 2026-09-14, capa por capa

La Matriz de Trazabilidad Cliente v1.1 cita este ID 4 veces (`TR-M04-110`, `TR-M04-112`, `M04-RGL-024`,
`M04-RGL-026`) como lo que reemplazó la fórmula `max(piso, ingreso×5%)`. Ningún documento del paquete
Kabeli reproducía su contenido, así que se preguntó directamente a Walvy. Respuesta del mismo día, con
el estado real capa por capa:

| Capa | Estado real |
|---|---|
| Retirar `max(piso, ingreso×5%)` en M04 | **CERRADO** |
| M05 como owner de protección prudencial | **CERRADO** |
| `P4-CNT-022` consumidor con 3 estados | **CERRADO** |
| Política de Reserva M05 3M/6M | **CERRADA** |
| Propagación de Reserva dentro de M05 | **HECHA posteriormente** |
| Mapping Reserva M05 → outcome `P4-CNT-022` | **NO ENCONTRADO como contrato cerrado** |
| Contrato técnico M05 → M04 con payload/version/provenance | **FALTA FORMALIZAR** |

Y en palabras del PMO: *"esta la definición pero no se aterrizó en la entrega [...] voy a sacar la
propagación entonces para poder actualizarte el paquete."*

**Lectura para este plan:**

1. **La sospecha sobre "Reserva" se confirma en ambos sentidos.** Sí es un concepto real y cerrado del
   lado de M05 (política 3M/6M), pero **su mapping hacia el outcome de `P4-CNT-022` no existe como
   contrato cerrado** — exactamente la advertencia que ya había dado el PMO ("no reutilizar 3/6 meses
   como supuesto colchón"). No usar Reserva como proxy del outcome prudencial sin que ese mapping se
   cierre explícitamente.
2. **Lo único que falta formalizar es el contrato técnico M05→M04** (payload + version + provenance).
   Todas las decisiones funcionales de arriba (retirar 5%, M05 owner, 3 estados) ya están cerradas — no
   hay nada pendiente de Producto. Esto es exactamente §2 opción B de este plan, ahora con confirmación
   de que el bloqueo es de **formalización de contrato**, no de política.
3. **Pendiente de Walvy:** actualizar el paquete de documentación con la propagación de esta decisión.
   Cuando llegue esa actualización, revisar si define el mapping Reserva→outcome o si sigue abierto, y si
   trae el contrato técnico M05→M04 (forma del payload, versión, evaluabilidad) que el `PrudentialOutcomePort`
   stub va a necesitar implementar contra algo real.
