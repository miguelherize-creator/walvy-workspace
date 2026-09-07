# M4 — Deuda técnica

**Revisado:** 2026-09-06 contra `origin/qa` de `back-walvy` y `front-walvy`.

> Las dos afirmaciones de la versión anterior de este archivo eran **falsas**: decían que
> el backend de deudas no existía y que la regla de severidad no estaba escrita. Ambas
> quedaron obsoletas y sirvieron de base para decisiones equivocadas. Ver «Lo que dejó
> de ser deuda».

---

## Lo que sí es deuda hoy

### 1 · El adaptador de `PressureInputs` — el bloqueo real

`debts.module.ts` inyecta `NullPressureInputsAdapter`, que devuelve todo en `null`. Sin
ingreso canónico ni headroom (**M05**), ni hecho de pago ni aging (**M06**), el motor P4
corre pero no concluye: la presión sale `no_calculable` y la salud `sin_datos_suficientes`.

**Consecuencia:** los escenarios En Control / Atención / Riesgo **no son reproducibles en
QA**. Todo usuario cae en el mismo estado.

**No es que falte el motor.** El motor está completo y cableado. Falta un adaptador — un
archivo. Un adaptador de fixtures detrás de un flag desbloquearía QA sin esperar a la
entrega de M05. **Sin dueño asignado.**

### 2 · Tres estados del contrato sin frame

OD-03 define cinco lecturas del Resultado. Figma dibujó dos. Hoy 🟡 Atención,
🔴 Riesgo-con-gate-incompleto y ⚪️ No calculable comparten una **card neutra provisional**
—sin mascota, con los neutros del sistema— que dice «Aún no podemos concluir».

Es honesto pero incompleto: la app no puede representar estados que el contrato exige.
**Bloqueado por Diseño.**

### 3 · Dos reglas escritas y sin cablear

`sustainability-gate` y `selected-plan` están completas y probadas, sin ningún camino que
las llame. No son deuda accidental: son **inversión adelantada** contra el contrato, a la
espera de M05 y de la pantalla de simulación de aporte. Se listan para que nadie las
crea muertas.

### 4 · El 27% de capacidad comprometida

El frame del «Resumen del análisis» muestra un porcentaje que ninguna regla calcula. El
Anexo BDD prohíbe «usar porcentajes o indicadores visibles en Figma como fórmula, score o
threshold funcional», así que **no se derivó**. Necesita que Producto lo declare como
regla o que salga del diseño.

### 5 · El front consume una forma que el backend no devuelve

`getCurrentRoute()` en `expo/api/debtsService.ts` tipa la respuesta de
`GET /debts/route/current` como `RouteProgress` —`planId`, `progressPct`,
`recentPayments`—, y el backend devuelve `RouteStatus`: elegibilidad, activación,
review y plan. Ninguno de esos tres campos existe.

**Seis pantallas de Ruta Despeje** consumen ese tipo. Está anotado en el código
como trabajo de la etapa 2. **Owner: M04 front.**

### 6 · `transactionId` promete idempotencia y no la tiene

El DTO de `POST /debts/:id/payments` describe el campo como «(idempotencia)». No
hay índice único en `debt_payments.transaction_id` ni chequeo previo: dos POST con
el mismo `transactionId` insertan dos abonos y descuentan el saldo dos veces. El
`COMMENT ON COLUMN` del esquema dice lo correcto —«Movimiento con el que se
concilió el abono»—; la promesa está sólo en la descripción de Swagger.

Importa ahora porque **M07** es quien va a registrar pagos, y un reintento suyo
hoy corrompe el saldo. Se cierra con un índice único o borrando la promesa del
DTO. **Sin dueño asignado.**

---

## Lo que dejó de ser deuda

| Antes | Estado |
|---|---|
| «Backend de deudas no implementado» | **Falso desde ago-2026.** Módulo completo: 16 reglas, 3 servicios, 12 endpoints, 438 tests |
| «`evaluateDebtSeverity` no existe» | **Falso.** Existía desde jun-2026 — y se **borró** el 2026-09-06 por quedar sin dueño (ver abajo) |
| `GET /debts/result` ausente | **Descartado**, no pendiente. El contrato no define esa forma; presión y gate se publican en `GET /debts/route/current` |
| El Resultado afirmaba «En Control» sin evaluar | **Corregido** en `front-walvy#159` |
| «Ver Ruta» navegaba a Movimientos | **Corregido** en `front-walvy#160` |

### Por qué `debt-severity` sobrevivió tanto

Nació el 2026-06-28 en el primer commit de M04, como semáforo por vencimiento, **dos meses
antes de que llegara el contrato del cliente** (2026-08-31). Cuando llegó, el eje cambió:
el color sale de C×K×D, y el vencimiento pasó a Salud de Deuda con owner operativo M06.

La regla quedó huérfana pero **no se veía muerta**: el 2026-08-20 se le había agregado
encima `hasMoraConfirmada`, que sí estaba en uso desde M01. El archivo seguía importado,
así que un `grep` superficial lo daba por vivo.

**Lección para este README:** «existe un import» no es «está cableado». Verificar contra
los controllers.

---

## Cómo verificar este archivo

```bash
cd back-walvy && npx jest src/debts     # 438 tests, 27 suites
grep -rn "NullPressureInputsAdapter" src/debts/debts.module.ts
```

Contratos vivos: `back-walvy/docs/api/debts/route.md` ·
[`../motor-m04-en-detalle.md`](../motor-m04-en-detalle.md) ·
[`../plan-cierre-semaforo-resultado.md`](../plan-cierre-semaforo-resultado.md)
