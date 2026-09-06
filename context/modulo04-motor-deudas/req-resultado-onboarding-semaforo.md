# REQ · Resultado del Onboarding de Deudas (paso 3) — presión vs elegibilidad

**Estado:** abierto — decisión acotada. **No es un ticket de implementación.**
**Audiencia:** Producto, Diseño, Backend (M04), Frontend (deudas).
**Superficie:** `/(tabs)/debts-result` · Paso 3 de 3 (Carga → Revisión → Resultado).
**No es:** el semáforo G5 de M01 (`onboarding-first-ready`). Son dos lecturas distintas.
**Fecha:** 2026-09-06 · **revisado contra código y entrega v1.0 del cliente el 2026-09-06.**

> **Cambio respecto de la v1 de este documento.** La v1 planteaba elegir entre el semáforo A/B/C de Figma y el binario de Ruta del código. Esa disyuntiva está **superada**: la entrega `Walvy_M04_Entrega_Kabeli_v1.0` contiene la especificación de esta pantalla (OD-03), y ninguna de las dos opciones la cumple. La v1 además apoyaba tres afirmaciones sobre el código que hoy son falsas (motor P4, pantallas de Ruta, rol de `debt-severity`). Ver §3 y §5.

---

## 1 · Para qué existe este requerimiento

La pantalla de Resultado se construyó sin frame y sin REQ, tomando prestada la lectura de G5. Después llegó el contrato funcional del cliente, que **sí especifica esta pantalla**, y nadie reconcilió las dos cosas.

Hoy hay un defecto en producción que se puede escalar como incumplimiento de la entrega v1.0, no como opinión de diseño: **la app afirma «En Control» cuando el motor de presión no evaluó nada.**

El entregable de esta revisión es una **decisión escrita** sobre los dos puntos que el contrato no cubre (§7), más el reconocimiento de lo que el contrato ya cerró (§2). No es un PR.

---

## 2 · La fuente de verdad: OD-03 del contrato funcional

**Fuente:** [`Walvy_M04_Documentacion_Funcional_Consolidada_v1.0.docx`](../../../../documentacion/modulo04-update/Módulo%204/Walvy_M04_Entrega_Kabeli_v1.0/01_CONTRATO_FUNCIONAL/) §8.3 · «OD-03 · Resultado / derivación». Respaldado por el `Walvy_M04_Anexo_BDD_Reglas_Productivas_v1.0.docx` en la misma carpeta.

| Estado de presión | Derivación que manda el contrato |
|---|---|
| **En Control** | seguimiento/detalle; puede existir CTA operativo M06 sin cambiar ownership |
| **Atención** | revisión preventiva/contextual; **no Ruta automática** |
| **Riesgo · gate incompleto** | resolver F2 Confirmar / F1 Completar / F3 Actualizar — **no se expone Ruta** |
| **Riesgo · confirmación + suficiencia** | Ruta **elegible/prioritaria**, no activa hasta «Seguir plan» |

La señal visible canónica es la **presión** (`En Control` / `Atención` / `Riesgo`), no un color derivado del vencimiento. El campo canónico es `pressure_evaluation_status`, con vocabulario *no evaluada / sin presión / posible presión / bajo presión / no calculable*.

**Guardrails textuales del contrato que aplican a esta pantalla:**

- «**No convertir missing en cero ni fabricar En Control por falta de evidencia.**»
- «Un faltante material **bloquea En Control**.» (§10.1, gate de calidad)
- «**No fabricar Ruta desde Atención o datos insuficientes.**»
- «Riesgo con gate bloqueado **≠** CTA Ruta.» (Anexo BDD, §19.5 y antipatrones)
- «**No usar porcentajes o indicadores visibles en Figma como fórmula, score o threshold funcional.**»
- «No usar aging operativo como trigger automático F4/F5 cuando Presión no lo determine.»

El último cierra el rol de `debt-severity.rule.ts`: el aging pertenece a **Salud** (Sana / Requiere atención / Presionada, owner operativo M06), no al semáforo de Resultado.

---

## 3 · Qué queda de las tres historias anteriores

| Fuente | Veredicto |
|---|---|
| **Figma / QA del paso 3** — verde sin ruta; amarillo y rojo **ambos** con CTA de Ruta | **Rechazado en el escenario B.** Amarillo = Atención, y el contrato dice «no Ruta automática». El rojo tampoco expone Ruta si el gate está incompleto. Figma es referencia visual, no contrato (guardrail explícito). |
| **Wiki de código** [`recorrido-de-pantallas.md`](../wiki-codigo/recorrido-de-pantallas.md) — binario ¿se habilita Ruta? | **Incompleto.** El CTA sí es binario (Ruta o no), pero la pantalla tiene tres lecturas de presión. Hay que actualizarla. |
| **Diseño objetivo M04** [`contexto/debts-manual-entry.md`](contexto/debts-manual-entry.md) §3 — semáforo verde/amarillo/rojo/gris + `GET /debts/result` con `trafficLight` | **Obsoleto.** El contrato no define esta pantalla por vencimiento y no existe `trafficLight` como campo canónico. Marcar §3 como histórico. |
| **Deuda técnica M04** [`deuda-tecnica/README.md`](deuda-tecnica/README.md) | **Falso en ambas mitades hoy.** `evaluateDebtSeverity` existe; y el `GET /debts/result` que reclama no debe construirse (§6). Reescribir. |
| **Preguntas abiertas** [`preguntas-abiertas-producto.md`](preguntas-abiertas-producto.md) §3 — «se construyó sin frame» | **Cierto históricamente, ya no vigente como bloqueo.** OD-03 es el frame funcional. Actualizar. |
| **API M04-A** `back-walvy/docs/api/debts/route.md` | **Vigente pero incompleto.** Describe elegibilidad; no publica presión, que es lo que esta pantalla necesita (§5c). |
| **G5 (M01)** [`G5-diagnostico.md`](../specs/wiki/onboarding/requerimiento_por_puerta/G5-diagnostico.md) | **Confirmado como otro producto.** Salud del mes ≠ presión de deuda. El copy y las mascotas se reutilizaron; la señal no. |

---

## 4 · Qué hace el código (hechos verificados el 2026-09-06)

### Backend

**El motor P4 existe y está cableado.** `pressure-matrix.rule.ts` transcribe las 27 celdas C×K×D de §6.4; `pressure-floors.rule.ts` implementa RGL-020/021/022; y `debt-evaluation.pipeline.ts` los ejecuta por deuda antes de resolver elegibilidad.

Lo que falta es **solo el adaptador de entradas**. `debts.module.ts:33` inyecta `NullPressureInputsAdapter`, que devuelve:

```
ingresoMensualCanonico: null   // owner M05
headroomRatio: null            // owner M05
hechoPagoPorDeuda: {}          // owner M06
```

Con eso `computeC` y `computeK` no producen banda —correctamente, porque el contrato prohíbe asignar C1 por defecto— y la presión final sale `null`.

> Esto **no es** «falta el motor P4». Es un archivo de adaptación pendiente. Cambia por completo la pregunta de QA (§7).

**`evaluateRouteEligibility()`** · `route-eligibility.rule.ts` — implementa el gate del contrato (deuda confirmada + datos mínimos + presión `riesgo`) y **no degrada**: con `pressure === null` devuelve `pendiente_datos` con razón `route_pressure_not_evaluated`. Es correcto y respeta el guardrail.

**`evaluateDebtSeverity()`** · `debt-severity.rule.ts` — **código muerto**. Ningún controller ni servicio la llama. El único export vivo del archivo es `hasMoraConfirmada`, consumido desde `imports/services/statement-import.service.ts:1674` para otro fin. Evalúa vencimiento a 3/7 días, que por contrato es dominio de Salud/aging, no de esta pantalla.

**No existe `GET /debts/result`.** Los endpoints de deudas son `route/current`, `route/apply`, `route/close-debt`, `GET /`, `GET /summary`, `GET /:id`, `POST /`, `PATCH /:id`, `:id/confirm`, `:id/dismiss`, `:id/payments`.

### Frontend

`resolveResultVariant()` · [`resultVariant.ts`](../../../../front-walvy/expo/features/debts/resultVariant.ts) lee **solo** `GET /debts/route/current.eligibility`:

| Condición (en orden de evaluación) | Variante | Render real |
|---|---|---|
| `confirmedCount === 0` | `no_confirmed` | Verde «En Control» + Revisar mis pagos |
| `elegible` \| `activa` | `ruta_disponible` | Ámbar «Atención» + Ver Ruta Despeje |
| `pendiente_datos` \| `pendiente_confirmacion` | `no_confirmed` | **El mismo verde** |
| resto (`null`, `no_elegible`, `cerrada`) | `sin_presion` | **El mismo verde** |

Dos observaciones que la v1 de este documento no registraba:

- **`no_elegible` es el único caso que legítimamente puede decir «En Control»** — significa evaluado y sin presión. Hoy comparte render con `pendiente_datos`, que significa lo contrario.
- **`ResultVariant` tiene tres valores y dos renders.** `sin_presion` y `no_confirmed` producen UI idéntica byte a byte. El tipo carga una distinción que la pantalla descarta.

**Destinos de los CTA:**

| Botón | Código hoy | Estado real |
|---|---|---|
| Revisar mis pagos | `/(tabs)/payments` | M06 · tab stub, no construido |
| Ver Ruta Despeje | `/(tabs)/movimientos` | **Bug.** Ruta **sí está construida**: existen y están ruteadas `debt-route`, `debt-route-plan`, `debt-route-plan-detail`, `debt-route-progress`, `debt-route-close`, `debt-route-considered`. El comentario que llama «placeholder» a ese `replace` está desactualizado. |

---

## 5 · Los tres defectos

### a) «En Control» fabricado — incumplimiento de contrato

El back se guarda de afirmar; el front lo afirma igual.

`GET /debts/route/current` → `pendiente_datos` (presión `null`, razón `route_pressure_not_evaluated`) → `resolveResultVariant` → `no_confirmed` → card verde con el copy *«Tus pagos están al día, por lo que no se requiere activar una Ruta Despeje de Deudas.»*

Contra: «**No convertir missing en cero ni fabricar En Control por falta de evidencia**» y «un faltante material **bloquea** En Control».

Es el único camino visible en QA hoy, así que **todo usuario ve esta afirmación falsa**, incluido uno con una deuda vencida.

### b) «Ver Ruta» navega a Movimientos

`DebtResultScreen.tsx` hace `router.replace("/(tabs)/movimientos")` con un comentario que dice que Ruta «todavía no está construida». Ya lo está. Defecto de navegación independiente de cualquier decisión de producto.

### c) La API no publica presión — causa raíz de (a)

`route.service.current()` devuelve `eligibility`, `state`, `basis`, `reasonCodes`, `activatedAt`, `entry`, `review`, `plan`. **No devuelve presión.** El pipeline la calcula por deuda y la descarta al serializar.

El front no puede distinguir En Control de Atención porque nadie se lo dice. El gap real **no** es el `GET /debts/result` con `trafficLight` del doc de diseño viejo: es exponer `pressure_evaluation_status` —el campo que el contrato nombra como canónico— en `route/current`.

---

## 6 · Criterio de cierre

El contrato ya eligió. La decisión pendiente es de UX sobre dos casos que OD-03 no detalla.

**Opción vigente — Presión (OD-03).** La pantalla muestra el estado de presión del contrato. El CTA de Ruta aparece **solo** con Riesgo + gate completo. Atención muestra revisión preventiva sin Ruta. Riesgo con gate incompleto dirige a F2/F1/F3. `no calculable` no puede pintar En Control.

Las dos opciones de la v1 quedan **históricas**: la de Figma (A/B/C) porque viola el gate en B y C; la binaria porque pierde la distinción En Control / Atención, que sí es canónica.

Backend publica presión + estado de gate; front traduce a paleta y copy. Esto **no** es el híbrido que la v1 prohibía: la elegibilidad no pinta color, la presión sí, y el gate decide el CTA — que es exactamente lo que el contrato describe.

---

## 7 · Preguntas que siguen abiertas

Cinco. Las demás quedaron cerradas por contrato — ver §8.

### Producto / Diseño

1. **¿Qué se pinta cuando la presión es `no calculable`?** El contrato prohíbe En Control y no define la alternativa. Opciones: card gris neutra con copy explícito («todavía no podemos leer tu presión»), o mantener la pantalla en un estado de completitud. **Requiere frame nuevo.**
2. **¿M06 es destino válido del CTA de En Control antes de que el módulo exista?** El contrato admite «CTA operativo M06» en En Control, pero el tab es un stub. ¿Se oculta, se deshabilita o cambia de copy?
3. **¿Existen frames de Atención (sin Ruta) y de Riesgo-gate-incompleto?** Son dos estados que el contrato exige y que Figma no dibujó, porque Figma modeló amarillo y rojo como si ambos abrieran Ruta.

### Backend

4. **¿Se publica `pressure_evaluation_status` en `route/current`, o se abre un endpoint aparte?** Recomendación: extender `route/current`, que ya corre el pipeline completo y ya es el contrato vivo. **No** construir el `GET /debts/result` con `trafficLight` del doc viejo.
5. **¿Quién escribe el adaptador de `PressureInputs` y contra qué?** Hoy `NullPressureInputsAdapter`. Sin él, `elegible` no ocurre en QA. Como es un adaptador y no un motor, cabe un adaptador de fixtures detrás de un flag para desbloquear QA antes de que M05/M06 entreguen.

---

## 8 · Preguntas cerradas por la entrega v1.0

Para trazabilidad de la v1 de este documento.

| v1 | Respuesta |
|---|---|
| ¿Semáforo de vencimiento o binario de Ruta? | **Ninguno.** Presión En Control / Atención / Riesgo con gate (OD-03). |
| ¿El rojo es obligatorio en MVP? | Sí, pero **rojo ≠ Ruta**. Riesgo con gate incompleto va a F2/F1/F3. |
| ¿«En Control» con presión no calculada? | **No.** Prohibido textualmente. Es el defecto §5a. |
| ¿Es la misma lectura que G5? | **No.** Confirmado: G5 es salud del mes. |
| ¿`evaluateDebtSeverity` es contrato? | **No** para esta pantalla. Aging pertenece a Salud/M06. Es código muerto: evaluar si se borra o se reserva documentadamente. |
| ¿Se depreca para no tener dos verdades? | Sí. La única fuente de la señal es P4 + gate. |
| ¿Cuándo es realista `elegible` en QA? | Cuando exista el adaptador de `PressureInputs` — no cuando «entregue el motor», que ya está. Ver pregunta 5. |
| El copy ámbar «atraso confirmado» | **Incorrecto.** Riesgo es un estado financiero (C×K×D + floors), no una mora. Reescribir. |
| ¿«Ver Ruta» debe ir a `/(tabs)/debt-route`? | Sí. Ruta está construida. Es el defecto §5b. |

---

## 9 · Cómo reproducir en QA

1. **Camino único hoy.** Confirmar ≥1 deuda con cuota y vencimiento → Resultado.
   **Sale:** verde «En Control» + Revisar mis pagos, aunque la deuda esté vencida.
   **Motivo:** `route/current` → `pendiente_datos`, presión `null` por el adaptador Null.

2. **Con stub.** Interceptar el GET y devolver `"eligibility": "elegible"`.
   **Sale:** ámbar «Atención» + Ver Ruta. El botón navega a **Movimientos**, no a Ruta Despeje.

3. **Atención y Riesgo-sin-gate.** No hay pasos. La app no puede representar esos estados: no llegan por la API.

**Contrato vivo:** `GET /debts/route/current` (`eligibility`, `reasonCodes`).
**Ausente y necesario:** presión en esa misma respuesta.
**Documentado y descartado:** `GET /debts/result` con `trafficLight`.

Tests de front que fijan el binario actual y habrá que reescribir: `front-walvy/expo/features/debts/__tests__/DebtResultScreen.test.tsx` y `resultVariant.test.ts`.

---

## 10 · Fuentes de código citadas

| Pieza | Ruta |
|---|---|
| Contrato funcional del cliente | `documentacion/modulo04-update/Módulo 4/Walvy_M04_Entrega_Kabeli_v1.0/01_CONTRATO_FUNCIONAL/` |
| Variante de Resultado | `front-walvy/expo/features/debts/resultVariant.ts` |
| Pantalla + CTA + `replace` a Movimientos | `front-walvy/expo/features/debts/ui/DebtResultScreen.tsx` |
| Pantallas de Ruta (construidas) | `front-walvy/expo/app/(tabs)/debt-route*.tsx` |
| Motor P4 · matriz C×K×D | `back-walvy/src/debts/rules/pressure-matrix.rule.ts` |
| Motor P4 · floors RGL-020/021/022 | `back-walvy/src/debts/rules/pressure-floors.rule.ts` |
| Orquestación (calcula presión, la descarta) | `back-walvy/src/debts/services/debt-evaluation.pipeline.ts` |
| Adaptador Null de entradas M05/M06 | `back-walvy/src/debts/ports/pressure-inputs.port.ts` · `debts.module.ts:33` |
| Serialización de `route/current` | `back-walvy/src/debts/services/route.service.ts` |
| Gate de elegibilidad | `back-walvy/src/debts/rules/route-eligibility.rule.ts` |
| Aging · código muerto para esta pantalla | `back-walvy/src/debts/rules/debt-severity.rule.ts` |

---

## 11 · Fuera de alcance

- Implementar M06 o el stepper Plan / Avance de Ruta.
- Rediseñar G5.
- Este documento **no autoriza** a cablear `GET /debts/result` ni a construir la card roja como CTA de Ruta.
- Los defectos §5a y §5b son accionables por separado y **no dependen** de las preguntas de §7.
