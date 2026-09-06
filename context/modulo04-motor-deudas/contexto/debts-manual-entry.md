# Módulo 4 — Ruta Despeje · Backend

> # ⚠️ DOCUMENTO HISTÓRICO — no usar como contrato
>
> **Superado el 2026-09-06.** Escrito en jun-2026 como *diseño objetivo*, **dos meses antes
> de que llegara el contrato del cliente** (`Walvy_M04_Entrega_Kabeli_v1.0`, 2026-08-31).
> El backend que describe se construyó, pero **con otro modelo**.
>
> Se conserva por trazabilidad: explica de dónde salieron decisiones que después se
> revirtieron. **No refleja el código ni el contrato vigentes.**
>
> | Lo que dice | Lo vigente |
> |---|---|
> | El módulo Nest «no está implementado» | Completo desde ago-2026: 16 reglas, 10 endpoints, 451 tests |
> | Semáforo por **vencimiento** (3/7 días) | Presión **C×K×D** + floors — `pressure-matrix.rule.ts` |
> | `evaluateDebtSeverity()` decide el color | Regla **borrada** el 2026-09-06. El aging pasó a Salud de Deuda (owner M06) |
> | Contrato `GET /debts/result` con `trafficLight` | **Descartado.** Presión y gate van en `GET /debts/route/current` |
> | Amarillo y rojo comparten CTA de Ruta | Sólo **Riesgo con el gate completo** ofrece Ruta — OD-03 |
>
> **Fuentes vigentes:** [`../motor-m04-en-detalle.md`](../motor-m04-en-detalle.md) ·
> [`../req-resultado-onboarding-semaforo.md`](../req-resultado-onboarding-semaforo.md) ·
> `back-walvy/docs/api/debts/route.md`

**Módulo NestJS (objetivo):** `back-walvy/src/debts/`
**Relacionado:** [`debts.md`](../../specs/debts.md) (snowball / plan)

Ruta Despeje tiene **3 funcionalidades**: **1. Carga** · **2. Revisión** · **3. Resultado**.
Este documento es la fuente de verdad del backend de las 3.

---

## 1. Carga

Dos vías de entrada; ambas crean filas en `debts` que nacen `confirmation_status = unconfirmed`.

| Vía | Estado |
|---|---|
| **PDF de cartola (Kread)** | ✅ Cubierto por el pipeline de imports (fuera de este doc) |
| **Ingreso manual** | ✅ `POST /debts` |

### `POST /debts` — ingreso manual

Para préstamos personales, deudas informales o compromisos sin documento. Captura tolerante: 4 campos obligatorios, el resto se completa en Revisión.

```jsonc
POST /debts                       // JWT
{
  "name": "Préstamo Pedro",       // obligatorio
  "debtType": "prestamo_personal",// obligatorio — ver catálogo
  "currentBalance": 100000,       // obligatorio
  "minimumPayment": 25000,        // null si marcó "no sé la cuota"
  "installmentsRemaining": 5,
  "installmentsTotal": 10,
  "nextDueDate": "2026-07-05"
}
→ 201  { id, status: "active", confirmationStatus: "unconfirmed", dueDay: 5,
         metadata: { source: "manual_entry" }, ... }
```

**Catálogo `debtType`** (enum `DEBT_TYPES`, fuente de verdad front↔back):
`tarjeta_credito` · `credito_consumo` · `credito_automotriz` · `credito_hipotecario` · `prestamo_personal` · `deuda_informal` · `linea_credito` · `otro_compromiso`

**Decisiones aplicadas en el service:**
- `due_day` ← se deriva del día de `nextDueDate` (`null` si no viene).
- Campo "¿cómo la identificas?" → `name`. `creditorLabel` queda `null` por ahora.
- `metadata.source = "manual_entry"`; si la cuota viene `null` → `metadata.unknownMinimumPayment = true`.
- `status: "active"`, `currency` default `CLP`.

---

## 2. Revisión

Toda deuda debe ser confirmada por el usuario. A primera instancia no hay "Confirmadas", solo "Por confirmar". Las `confirmed` son las únicas que entran al plan de Ruta Despeje.

**`confirmation_status`** (columna nueva en `debt`): `unconfirmed` (default) · `confirmed` · `dismissed`.
**"Faltan Datos"** NO se almacena: se **calcula** (`missingFields`). Una deuda completa requiere `minimumPayment` + `nextDueDate` (constante `REQUIRED_FOR_CONFIRMATION`).

| Endpoint | Qué hace |
|---|---|
| `GET /debts?status=` | Lista del usuario; filtro opcional `unconfirmed`/`confirmed`/`dismissed`. Cada item: `confirmationStatus`, `origin` (`manual`/`document`), `needsData`, `missingFields[]`. |
| `GET /debts/summary` | `{ unconfirmed, confirmed, dismissed, canViewResult }`. `canViewResult = unconfirmed === 0` → habilita "Ver resultado". |
| `GET /debts/:id` | Detalle: + `paidInstallments` (cuota X/Y), `paymentState` (`al_dia`/`atrasado`), `lastPayment` (de `debt_payments`). |
| `PATCH /debts/:id` | Completar/editar (para "Faltan Datos" y "Ver detalles"). Recalcula `dueDay` y `unknownMinimumPayment`. |
| `POST /debts/:id/confirm` | `→ confirmed`. **400 si faltan datos requeridos.** Aplica a deudas manuales y de documento. |
| `POST /debts/:id/dismiss` | `→ dismissed` (descartar; se conserva, no entra al plan). **No** es borrado. |

**Mapeo al wireframe:** "Deudas por confirmar: N" → `summary.unconfirmed` · card → item de `GET /debts` · "Ver detalles" → `GET /debts/:id` · Confirmar/Descartar → endpoints · "Ver resultado" deshabilitado → `summary.canViewResult`.

---

## 3. Resultado (semáforo) — ⛔️ SUPERADO

> Toda esta sección quedó sin efecto. El color **no** sale del vencimiento sino de la
> presión C×K×D, el rojo se parte en dos según el gate, y existe un quinto estado
> —`no calculable`— que este diseño no previó. Ver
> [`../paso-3-resultado-en-detalle.md`](../paso-3-resultado-en-detalle.md).
>
> Lo único que sobrevivió es el principio de arquitectura del párrafo siguiente: **el
> backend decide, el front pinta.** Ese sigue vigente.

Pantalla tipo semáforo (verde / amarillo / rojo / gris) con mensaje, avatar y CTA.

**Arquitectura:** el **backend decide** el bucket; el **frontend solo pinta** (color, avatar, copy, CTA). La decisión NO vive en el cliente para evitar drift entre superficies (Resultado, Home/salud financiera, notificaciones, IA).

**Estado (obsoleto):** decía que `evaluateDebtSeverity()` no existía. Sí existía —desde el
2026-06-28— y nunca se cableó; se **borró** el 2026-09-06. El `GET /debts/result` que
propone no se construyó ni se construirá: quedó descartado por el contrato.

**Forma del resultado (contrato propuesto):**
```jsonc
{
  "trafficLight": "red",            // green | yellow | red | gray  ← el front pinta esto
  "paymentsState": "con_atraso",    // al_dia | en_observacion | con_atraso
  "confirmedCount": 2,
  "redirectTarget": "ruta_despeje", // "pagos" (verde) | "ruta_despeje" (amarillo/rojo)
  "ruleVersion": "v1_mvp",
  "reasons": [ ... ]                // transparencia
}
```

| trafficLight | Estado UI | paymentsState | CTA |
|---|---|---|---|
| 🟢 green | ¡Felicidades! | al_dia | → Pagos (mód 6) |
| 🟡 yellow | Atención | en_observacion | → Ver Ruta Despeje |
| 🔴 red | Riesgo | con_atraso | → Ver Ruta Despeje |
| ⚪ gray | Sin datos (S0) | — | — |

### ⚠️ Pregunta abierta para NEGOCIO — regla del semáforo

No está definido qué determina el color. Factores candidatos (pueden combinarse):

| Factor | Estado | Nota |
|---|---|---|
| **(A)** Fechas de vencimiento / mora | ✅ Implementado en `v1_mvp` | Reusa regla de pagos (M7): verde >7d, amarillo 3–7d, rojo <3d o vencido |
| **(B)** Cantidad de deudas confirmadas | ⏳ Pendiente | hook comentado en el archivo |
| **(C)** Monto adeudado vs **capacidad económica mensual** (ratio deuda/ingreso) | ⏳ Pendiente | `monthlyCapacity` ya está en el input |
| **(D)** Señales S0–S4 (mora persistente, pago mínimo recurrente, "deuda con deuda") | ⏳ Pendiente | requiere tabla `debt_cycle` + doc de señales (Fase 3) |

> Cuando negocio confirme: ajustar umbrales/activar hooks **solo** en `debt-severity.rule.ts` y subir `RULE_VERSION`. No tocar el frontend.

---

## Modelo de datos

- **No se crearon tablas nuevas** para Carga/Revisión. La entity `debt` ya cubría los campos del formulario; solo se agregó la columna **`confirmation_status`** (entity + `schema.sql`).
- Lo que es trazabilidad/display va en **`debt.metadata`** (jsonb): `source`, `unknownMinimumPayment`.
- **Tablas que el PDF de análisis pedía crear y NO se crearon** (diferidas / redundantes):
  - `debt_recommendation` → usar la existente **`recommendation_events`** (`context='debt'`).
  - `debt_signal` → para MVP basta `severity`/`evaluated_at`; tabla de historial = post-MVP (Fase 3).
  - `debt_cycle` → solo si el ciclo de tarjeta entra al MVP (factor D).

---

## Decisiones abiertas

1. **Regla del semáforo** → negocio (ver tabla §3).
2. **`debt_cycle`** → ¿entra al MVP? (necesaria para factor D / severidad S0–S4 completa).
3. **`name` vs `creditorLabel`** → hoy solo `name`; evaluar campo dedicado de acreedor.
4. **`due_day`** → hoy derivado de `nextDueDate` (confirmar con producto).

---

## Archivos backend (`src/debts/`)

```
entities/debt.entity.ts            (+ columna confirmation_status)
enums/debt-type.enum.ts            DEBT_TYPES (8 valores)
enums/confirmation-status.enum.ts  ConfirmationStatus + REQUIRED_FOR_CONFIRMATION
dto/create-debt.dto.ts
dto/update-debt.dto.ts
services/debts.service.ts          create / findAll / summary / findOne / update / confirm / dismiss
controllers/debts.controller.ts    POST /debts · GET · GET/summary · GET/:id · PATCH/:id · POST/:id/confirm · POST/:id/dismiss
rules/debt-severity.rule.ts        BORRADO 2026-09-06 — ver deuda-tecnica/README.md
debts.module.ts
```

**Última actualización:** 2026-06-27
